package com.genyleap.genyconnect;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.net.TrafficStats;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.system.Os;
import android.system.OsConstants;
import android.util.Log;

import java.io.File;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

public final class GenyConnectVpnService extends VpnService {
    public static final String ACTION_CONNECT = "com.genyleap.genyconnect.action.CONNECT";
    public static final String ACTION_DISCONNECT = "com.genyleap.genyconnect.action.DISCONNECT";
    public static final String ACTION_QUERY_STATE = "com.genyleap.genyconnect.action.QUERY_STATE";
    public static final String ACTION_START = ACTION_CONNECT;
    public static final String ACTION_STOP = ACTION_DISCONNECT;
    public static final String EXTRA_EXECUTABLE_PATH = "executable_path";
    public static final String EXTRA_CONFIG_PATH = "config_path";
    public static final String EXTRA_WORKING_DIRECTORY = "working_directory";

    private static final String NOTIFICATION_CHANNEL_ID = "genyconnect_vpn";
    private static final int NOTIFICATION_ID = 4317;
    private static final String TAG = "GenyConnectVpnService";
    private static final String XRAY_ASSET_NAME = "xray-core";
    private static final String XRAY_RUNTIME_FILE = "xray-core";
    private static final String XRAY_NATIVE_LIB_NAME = "libxraycore.so";
    private static final String PREFS_NAME = "genyconnect_vpn_runtime";
    private static final String PREF_LAST_EXECUTABLE_PATH = "last_executable_path";
    private static final String PREF_LAST_CONFIG_PATH = "last_config_path";
    private static final String PREF_LAST_WORKING_DIRECTORY = "last_working_directory";
    private static final String PREF_RUNNING = "runtime_running";
    private static final String PREF_LAST_ERROR = "runtime_last_error";
    private static final String PREF_BASE_UID_RX_BYTES = "base_uid_rx_bytes";
    private static final String PREF_BASE_UID_TX_BYTES = "base_uid_tx_bytes";

    private static volatile boolean sRunning = false;
    private static volatile String sLastError = "";
    private static volatile Process sXrayProcess = null;
    private static volatile ParcelFileDescriptor sTunnelInterface = null;
    private static volatile Context sAppContext = null;
    private static volatile long sBaseUidRxBytes = 0L;
    private static volatile long sBaseUidTxBytes = 0L;
    private static final ExecutorService sRuntimeExecutor = Executors.newSingleThreadExecutor();
    private static final AtomicBoolean sStartQueued = new AtomicBoolean(false);

    @Override
    public void onCreate() {
        super.onCreate();
        sAppContext = getApplicationContext();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        final String action = intent != null ? safeString(intent.getAction()) : "";
        if (ACTION_DISCONNECT.equals(action) || ACTION_STOP.equals(action)) {
            stopRuntime(true);
            stopSelf();
            return START_NOT_STICKY;
        }
        final boolean runtimeAlive = isRuntimeProcessAlive();
        if (ACTION_QUERY_STATE.equals(action)) {
            if (runtimeAlive) {
                persistRuntimeSnapshot(true, "");
                return START_STICKY;
            }
            sRunning = false;
            persistRuntimeSnapshot(false, sLastError);
            return START_NOT_STICKY;
        }
        if (runtimeAlive) {
            persistRuntimeSnapshot(true, "");
            return START_STICKY;
        }

        String executablePath = intent != null ? safeString(intent.getStringExtra(EXTRA_EXECUTABLE_PATH)) : "";
        String configPath = intent != null ? safeString(intent.getStringExtra(EXTRA_CONFIG_PATH)) : "";
        String workingDirectory = intent != null ? safeString(intent.getStringExtra(EXTRA_WORKING_DIRECTORY)) : "";
        if (configPath.isEmpty()) {
            executablePath = safeString(readPreference(PREF_LAST_EXECUTABLE_PATH));
            configPath = safeString(readPreference(PREF_LAST_CONFIG_PATH));
            workingDirectory = safeString(readPreference(PREF_LAST_WORKING_DIRECTORY));
        }
        if (!configPath.isEmpty()) {
            saveRuntimeLaunchConfig(executablePath, configPath, workingDirectory);
        }
        startForegroundInternal();
        enqueueStartRuntime(executablePath, configPath, workingDirectory);
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        if (!sRunning && !isRuntimeProcessAlive()) {
            stopRuntime(false);
        }
        super.onDestroy();
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        if (sRunning || isRuntimeProcessAlive()) {
            try {
                startForegroundInternal();
            } catch (Exception ignored) {
            }
            return;
        }
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public void onRevoke() {
        sLastError = "Android VPN permission was revoked by the system.";
        persistRuntimeSnapshot(false, sLastError);
        stopRuntime(false);
        stopSelf();
        super.onRevoke();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }

    public static boolean isRunning() {
        if (isRuntimeProcessAlive()) {
            return true;
        }
        return readBooleanPreference(PREF_RUNNING, false);
    }

    public static String lastError() {
        if (sLastError != null && !sLastError.trim().isEmpty()) {
            return sLastError;
        }
        return safeString(readPreference(PREF_LAST_ERROR));
    }

    public static long rxBytes() {
        final long current = uidRxBytes();
        if (current < 0L) {
            return 0L;
        }
        final long base = sBaseUidRxBytes > 0L
            ? sBaseUidRxBytes
            : readLongPreference(PREF_BASE_UID_RX_BYTES, 0L);
        if (!isRunning() || base <= 0L) {
            return 0L;
        }
        return Math.max(0L, current - base);
    }

    public static long txBytes() {
        final long current = uidTxBytes();
        if (current < 0L) {
            return 0L;
        }
        final long base = sBaseUidTxBytes > 0L
            ? sBaseUidTxBytes
            : readLongPreference(PREF_BASE_UID_TX_BYTES, 0L);
        if (!isRunning() || base <= 0L) {
            return 0L;
        }
        return Math.max(0L, current - base);
    }

    private synchronized void startRuntime(String executablePath, String configPath, String workingDirectory) {
        if (isRuntimeProcessAlive()) {
            persistRuntimeSnapshot(true, "");
            return;
        }
        if (sRunning) {
            stopRuntime(false);
        }

        if (safeString(configPath).isEmpty()) {
            fail("Generated runtime config path is empty.");
            return;
        }

        clearError();
        startForegroundInternal();

        final String normalizedConfigPath = safeString(configPath);
        final String requestedExecutablePath = safeString(executablePath);
        final String normalizedWorkingDirectory = safeString(workingDirectory);

        final File configFile = new File(normalizedConfigPath);
        if (!configFile.exists()) {
            fail("Generated runtime config is missing: " + normalizedConfigPath);
            return;
        }
        final boolean requiresTunInbound = configRequestsTun(normalizedConfigPath);

        final String resolvedExecutablePath = resolveExecutablePath(requestedExecutablePath);
        if (resolvedExecutablePath.isEmpty()) {
            fail("xray-core executable is missing on Android. Rebuild APK with bundled xray-core.");
            return;
        }

        final File executableFile = new File(resolvedExecutablePath);
        if (!executableFile.exists()) {
            fail("xray-core executable is missing: " + resolvedExecutablePath);
            return;
        }

        if (!executableFile.canExecute()) {
            if (!resolvedExecutablePath.endsWith(XRAY_NATIVE_LIB_NAME) && !executableFile.setExecutable(true, false)) {
                fail("xray-core binary is not executable: " + resolvedExecutablePath);
                return;
            }
        }

        int tunFd = -1;
        int tunFdForXray = -1;
        FileDescriptor stdinBackup = null;
        if (requiresTunInbound) {
            try {
                final Builder builder = new Builder()
                    .setSession("GenyConnect")
                    .addAddress("10.22.0.2", 32)
                    .addRoute("0.0.0.0", 0)
                    .addDnsServer("1.1.1.1")
                    .addDnsServer("8.8.8.8");
                // Exclude this app UID from capture to prevent xray outbound
                // sockets from looping back into the same VPN tunnel.
                try {
                    builder.addDisallowedApplication(getPackageName());
                } catch (Exception exception) {
                    Log.w(TAG, "Failed to exclude app UID from VPN capture: " + exception.getMessage());
                }
                sTunnelInterface = builder.establish();
            } catch (Exception exception) {
                fail("Failed to establish Android VPN interface: " + exception.getMessage());
                return;
            }

            if (sTunnelInterface == null) {
                fail("Android VPN interface could not be created.");
                return;
            }

            tunFd = sTunnelInterface.getFd();
            if (tunFd <= 0) {
                fail("Android VPN tunnel fd is invalid.");
                return;
            }
            if (!prepareTunFdInheritance(sTunnelInterface.getFileDescriptor())) {
                fail("Failed to prepare inheritable Android VPN tunnel fd for xray-core.");
                return;
            }
            stdinBackup = remapTunToStdin(sTunnelInterface.getFileDescriptor());
            if (stdinBackup == null) {
                fail("Failed to remap Android VPN fd for xray-core child process.");
                return;
            }
            tunFdForXray = 0;
        } else {
            sTunnelInterface = null;
        }

        try {
            String effectiveWorkingDirectory = normalizedWorkingDirectory;
            if (effectiveWorkingDirectory.isEmpty() || !new File(effectiveWorkingDirectory).isDirectory()) {
                final File parent = executableFile.getParentFile();
                effectiveWorkingDirectory = parent != null ? parent.getAbsolutePath() : "";
            }

            final ProcessBuilder processBuilder = new ProcessBuilder(
                resolvedExecutablePath,
                "run",
                "-config",
                normalizedConfigPath
            );
            if (!effectiveWorkingDirectory.isEmpty()) {
                processBuilder.directory(new File(effectiveWorkingDirectory));
            }
            // Provide TUN fd to xray Android TUN inbound bootstrap only when tun inbound is active.
            if (requiresTunInbound && tunFdForXray >= 0) {
                processBuilder.environment().put("xray.tun.fd", Integer.toString(tunFdForXray));
                processBuilder.environment().put("XRAY_TUN_FD", Integer.toString(tunFdForXray));
                processBuilder.redirectInput(ProcessBuilder.Redirect.INHERIT);
            }
            processBuilder.redirectErrorStream(true);
            sXrayProcess = processBuilder.start();
            if (requiresTunInbound) {
                Log.i(TAG, "Started xray-core from: " + resolvedExecutablePath
                    + " (vpnFd=" + tunFd + ",xrayTunFd=" + tunFdForXray + ")");
            } else {
                Log.i(TAG, "Started xray-core from: " + resolvedExecutablePath + " (proxy-only mode)");
            }
            startProcessMonitor(sXrayProcess);
        } catch (IOException exception) {
            fail("Failed to start xray-core on Android: " + exception.getMessage());
            return;
        } finally {
            restoreStdin(stdinBackup);
        }

        sBaseUidRxBytes = uidRxBytes();
        sBaseUidTxBytes = uidTxBytes();
        writeLongPreference(PREF_BASE_UID_RX_BYTES, Math.max(0L, sBaseUidRxBytes));
        writeLongPreference(PREF_BASE_UID_TX_BYTES, Math.max(0L, sBaseUidTxBytes));
        sRunning = true;
        persistRuntimeSnapshot(true, "");
    }

    private void enqueueStartRuntime(String executablePath, String configPath, String workingDirectory) {
        if (!sStartQueued.compareAndSet(false, true)) {
            return;
        }

        final String queuedExecutablePath = safeString(executablePath);
        final String queuedConfigPath = safeString(configPath);
        final String queuedWorkingDirectory = safeString(workingDirectory);
        sRuntimeExecutor.execute(() -> {
            try {
                startRuntime(queuedExecutablePath, queuedConfigPath, queuedWorkingDirectory);
            } finally {
                sStartQueued.set(false);
            }
        });
    }

    private synchronized void stopRuntime(boolean userRequested) {
        sRunning = false;

        if (sXrayProcess != null) {
            try {
                sXrayProcess.destroy();
            } catch (Exception ignored) {
            }
            try {
                sXrayProcess.destroyForcibly();
            } catch (Exception ignored) {
            }
            sXrayProcess = null;
        }

        if (sTunnelInterface != null) {
            try {
                sTunnelInterface.close();
            } catch (IOException ignored) {
            }
            sTunnelInterface = null;
        }

        sBaseUidRxBytes = 0L;
        sBaseUidTxBytes = 0L;
        writeLongPreference(PREF_BASE_UID_RX_BYTES, 0L);
        writeLongPreference(PREF_BASE_UID_TX_BYTES, 0L);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE);
        } else {
            stopForeground(true);
        }
        if (userRequested) {
            sLastError = "";
        }
        persistRuntimeSnapshot(false, sLastError);
    }

    private void startForegroundInternal() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            new Handler(Looper.getMainLooper()).post(this::startForegroundInternal);
            return;
        }

        final NotificationManager notificationManager =
            (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (notificationManager == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            final NotificationChannel channel = new NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "GenyConnect VPN",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("GenyConnect secure tunnel runtime");
            notificationManager.createNotificationChannel(channel);
        }

        final Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            ? new Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            : new Notification.Builder(this);

        builder
            .setContentTitle("GenyConnect")
            .setContentText("VPN runtime is active")
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true);

        final Notification notification = builder.build();

        startForeground(NOTIFICATION_ID, notification);
    }

    private static String safeString(String value) {
        return value == null ? "" : value.trim();
    }

    private static android.content.SharedPreferences prefs() {
        Context appContext = sAppContext;
        if (appContext == null) {
            appContext = AndroidRuntimeBridge.appContext();
        }
        if (appContext == null) {
            return null;
        }
        return appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE | Context.MODE_MULTI_PROCESS);
    }

    private static String readPreference(String key) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return "";
        }
        return safeString(sharedPreferences.getString(key, ""));
    }

    private static boolean readBooleanPreference(String key, boolean fallback) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return fallback;
        }
        return sharedPreferences.getBoolean(key, fallback);
    }

    private static long readLongPreference(String key, long fallback) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return fallback;
        }
        return sharedPreferences.getLong(key, fallback);
    }

    private static boolean isRuntimeProcessAlive() {
        if (!sRunning || sXrayProcess == null) {
            return false;
        }
        try {
            return sXrayProcess.isAlive();
        } catch (Exception ignored) {
            return false;
        }
    }

    private static void writePreference(String key, String value) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return;
        }
        sharedPreferences.edit().putString(key, safeString(value)).commit();
    }

    private static void writeBooleanPreference(String key, boolean value) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return;
        }
        sharedPreferences.edit().putBoolean(key, value).commit();
    }

    private static void writeLongPreference(String key, long value) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return;
        }
        sharedPreferences.edit().putLong(key, value).commit();
    }

    private static void saveRuntimeLaunchConfig(String executablePath, String configPath, String workingDirectory) {
        writePreference(PREF_LAST_EXECUTABLE_PATH, executablePath);
        writePreference(PREF_LAST_CONFIG_PATH, configPath);
        writePreference(PREF_LAST_WORKING_DIRECTORY, workingDirectory);
    }

    private static void persistRuntimeSnapshot(boolean running, String errorText) {
        writeBooleanPreference(PREF_RUNNING, running);
        writePreference(PREF_LAST_ERROR, errorText);
    }

    private static boolean configRequestsTun(String configPath) {
        final String path = safeString(configPath);
        if (path.isEmpty()) {
            return false;
        }
        final StringBuilder content = new StringBuilder(4096);
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line);
                if (content.length() > 256 * 1024) {
                    break;
                }
            }
        } catch (Exception ignored) {
            return false;
        }

        final String normalized = content.toString().toLowerCase();
        return normalized.contains("\"protocol\":\"tun\"")
            || normalized.contains("\"protocol\": \"tun\"");
    }

    private String resolveExecutablePath(String requestedExecutablePath) {
        final String nativeLibPath = resolveNativeLibraryExecutablePath();
        if (!nativeLibPath.isEmpty()) {
            Log.i(TAG, "Using native library xray executable: " + nativeLibPath);
            return nativeLibPath;
        }

        if (!requestedExecutablePath.isEmpty()) {
            final File requestedFile = new File(requestedExecutablePath);
            if (requestedFile.exists()) {
                Log.w(TAG, "Using requested xray executable fallback: " + requestedFile.getAbsolutePath());
                return requestedFile.getAbsolutePath();
            }
            Log.w(TAG, "Requested xray path is missing; falling back to bundled asset: " + requestedExecutablePath);
        }

        final String extractedPath = extractBundledXrayAsset();
        if (!extractedPath.isEmpty()) {
            Log.w(TAG, "Using extracted asset xray executable fallback: " + extractedPath);
            return extractedPath;
        }

        return requestedExecutablePath;
    }

    private String resolveNativeLibraryExecutablePath() {
        try {
            final ApplicationInfo appInfo = getApplicationInfo();
            if (appInfo == null || safeString(appInfo.nativeLibraryDir).isEmpty()) {
                return "";
            }
            final File nativeExecutable = new File(appInfo.nativeLibraryDir, XRAY_NATIVE_LIB_NAME);
            if (!nativeExecutable.exists()) {
                return "";
            }
            return nativeExecutable.getAbsolutePath();
        } catch (Exception exception) {
            Log.w(TAG, "Failed to resolve nativeLibraryDir xray path: " + exception.getMessage());
            return "";
        }
    }

    private String extractBundledXrayAsset() {
        final File runtimeDir = new File(getFilesDir(), "runtime");
        if (!runtimeDir.exists() && !runtimeDir.mkdirs()) {
            Log.e(TAG, "Failed to create runtime directory: " + runtimeDir.getAbsolutePath());
            return "";
        }

        final File outFile = new File(runtimeDir, XRAY_RUNTIME_FILE);
        try (InputStream input = getAssets().open(XRAY_ASSET_NAME);
             FileOutputStream output = new FileOutputStream(outFile, false)) {
            final byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                output.write(buffer, 0, read);
            }
            output.flush();
        } catch (IOException exception) {
            Log.e(TAG, "Bundled xray-core asset is unavailable: " + exception.getMessage());
            return "";
        }

        if (!outFile.canExecute() && !outFile.setExecutable(true, false)) {
            Log.e(TAG, "Failed to mark bundled xray-core executable: " + outFile.getAbsolutePath());
            return "";
        }

        return outFile.getAbsolutePath();
    }

    private void startProcessMonitor(Process process) {
        if (process == null) {
            return;
        }
        final Thread monitor = new Thread(() -> {
            String lastLine = "";
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (!line.trim().isEmpty()) {
                        lastLine = line.trim();
                    }
                    Log.i(TAG, "xray-core: " + line);
                }
            } catch (IOException exception) {
                Log.w(TAG, "Failed to read xray-core output: " + exception.getMessage());
            }

            int exitCode = -1;
            try {
                exitCode = process.waitFor();
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                return;
            }

            synchronized (GenyConnectVpnService.this) {
                if (!sRunning || sXrayProcess != process) {
                    return;
                }
                if (lastLine.isEmpty()) {
                    sLastError = "xray-core exited unexpectedly with code " + exitCode + ".";
                } else {
                    sLastError = "xray-core exited unexpectedly with code " + exitCode + ": " + lastLine;
                }
                Log.e(TAG, sLastError);
                stopRuntime(false);
                stopSelf();
            }
        }, "genyconnect-xray-monitor");
        monitor.setDaemon(true);
        monitor.start();
    }

    private void clearError() {
        sLastError = "";
    }

    private void fail(String message) {
        sLastError = message == null ? "Unknown Android runtime failure." : message.trim();
        Log.e(TAG, sLastError);
        stopRuntime(false);
        stopSelf();
    }

    private static long uidRxBytes() {
        final long value = TrafficStats.getUidRxBytes(android.os.Process.myUid());
        return value == TrafficStats.UNSUPPORTED ? -1L : Math.max(0L, value);
    }

    private static long uidTxBytes() {
        final long value = TrafficStats.getUidTxBytes(android.os.Process.myUid());
        return value == TrafficStats.UNSUPPORTED ? -1L : Math.max(0L, value);
    }

    private static boolean prepareTunFdInheritance(FileDescriptor descriptor) {
        if (descriptor == null) {
            return false;
        }
        try {
            final int flags = Os.fcntlInt(descriptor, OsConstants.F_GETFD, 0);
            if ((flags & OsConstants.FD_CLOEXEC) != 0) {
                Os.fcntlInt(descriptor, OsConstants.F_SETFD, flags & ~OsConstants.FD_CLOEXEC);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static FileDescriptor remapTunToStdin(FileDescriptor tunDescriptor) {
        if (tunDescriptor == null) {
            return null;
        }
        try {
            final FileDescriptor backup = Os.dup(FileDescriptor.in);
            Os.dup2(tunDescriptor, 0);
            return backup;
        } catch (Exception exception) {
            Log.e(TAG, "Failed to remap TUN fd to stdin: " + exception.getMessage());
            return null;
        }
    }

    private static void restoreStdin(FileDescriptor backup) {
        if (backup == null) {
            return;
        }
        try {
            Os.dup2(backup, 0);
        } catch (Exception ignored) {
        }
        try {
            Os.close(backup);
        } catch (Exception ignored) {
        }
    }
}
