package com.genyleap.genyconnect;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.TrafficStats;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.os.PowerManager;
import android.os.SystemClock;
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
import java.lang.reflect.Method;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.ArrayDeque;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.JSONArray;
import org.json.JSONObject;

public final class GenyConnectVpnService extends VpnService {
    public static final String ACTION_CONNECT = "com.genyleap.genyconnect.action.CONNECT";
    public static final String ACTION_DISCONNECT = "com.genyleap.genyconnect.action.DISCONNECT";
    public static final String ACTION_RECONNECT = "com.genyleap.genyconnect.action.RECONNECT";
    public static final String ACTION_QUERY_STATE = "com.genyleap.genyconnect.action.QUERY_STATE";
    public static final String ACTION_REFRESH_NETWORK_CACHE = "com.genyleap.genyconnect.action.REFRESH_NETWORK_CACHE";
    public static final String ACTION_START = ACTION_CONNECT;
    public static final String ACTION_STOP = ACTION_DISCONNECT;
    public static final String ACTION_RESTART = ACTION_RECONNECT;
    public static final String EXTRA_EXECUTABLE_PATH = "executable_path";
    public static final String EXTRA_CONFIG_PATH = "config_path";
    public static final String EXTRA_WORKING_DIRECTORY = "working_directory";

    private static final String NOTIFICATION_CHANNEL_ID = "genyconnect_vpn_status";
    private static final int NOTIFICATION_ID = 4317;
    private static final String TAG = "GenyConnectVpnService";
    private static final String XRAY_ASSET_LEGACY_NAME = "xray-core";
    private static final String XRAY_ASSET_ROOT_NAME = "xray";
    private static final String XRAY_ASSET_DIR = "xray";
    private static final String XRAY_RUNTIME_FILE = "xray-core";
    private static final String XRAY_NATIVE_LIB_NAME = "libxraycore.so";
    private static final String PREFS_NAME = "genyconnect_vpn_runtime";
    private static final String PREF_LAST_EXECUTABLE_PATH = "last_executable_path";
    private static final String PREF_LAST_CONFIG_PATH = "last_config_path";
    private static final String PREF_LAST_WORKING_DIRECTORY = "last_working_directory";
    private static final String PREF_LAST_ERROR = "runtime_last_error";
    private static final String PREF_BASE_UID_RX_BYTES = "base_uid_rx_bytes";
    private static final String PREF_BASE_UID_TX_BYTES = "base_uid_tx_bytes";
    private static final String PREF_UI_PROCESS_PID = "ui_process_pid";
    private static final String PREF_UI_PROCESS_UPDATED_AT_MS = "ui_process_updated_at_ms";
    private static final String UI_PROCESS_STATE_FILE = "ui_process_state.txt";
    private static final String NOTIFICATION_ACTION_DISCONNECT_LABEL = "Disconnect";
    private static final String NOTIFICATION_ACTION_RECONNECT_LABEL = "Reconnect";
    private static final long NOTIFICATION_UPDATE_INTERVAL_MS = 1000L;
    private static final long MIN_RATE_SAMPLE_INTERVAL_MS = 400L;
    private static final long MAIN_THREAD_WARNING_MS = 350L;
    private static final int DIAGNOSTIC_HISTORY_LIMIT = 48;

    private static volatile boolean sRunning = false;
    private static volatile String sLastError = "";
    private static volatile String sLastRuntimeDiagnostics = "";
    private static volatile String sLastResolvedCoreAssetName = "";
    private static volatile Process sXrayProcess = null;
    private static volatile ParcelFileDescriptor sTunnelInterface = null;
    private static volatile Context sAppContext = null;
    private static volatile long sBaseUidRxBytes = 0L;
    private static volatile long sBaseUidTxBytes = 0L;
    private static final Object sDiagnosticsLock = new Object();
    private static final ArrayDeque<String> sRuntimeDiagnosticHistory = new ArrayDeque<>();
    private static final ExecutorService sRuntimeExecutor = Executors.newSingleThreadExecutor();
    private static final AtomicBoolean sStartQueued = new AtomicBoolean(false);
    private static final AtomicBoolean sStartCanceled = new AtomicBoolean(false);
    private final Object mRuntimeLock = new Object();
    private final Handler mNotificationHandler = new Handler(Looper.getMainLooper());
    private final Runnable mNotificationUpdater = new Runnable() {
        @Override
        public void run() {
            if (!sRunning && !isRuntimeProcessAlive()) {
                return;
            }
            refreshForegroundNotification(false);
            mNotificationHandler.postDelayed(this, NOTIFICATION_UPDATE_INTERVAL_MS);
        }
    };
    private long mNotificationLastRxBytes = -1L;
    private long mNotificationLastTxBytes = -1L;
    private long mNotificationLastSampleElapsedMs = 0L;
    private long mNotificationLastDownBytesPerSec = 0L;
    private long mNotificationLastUpBytesPerSec = 0L;
    private Bitmap mNotificationLargeIcon = null;
    private volatile boolean mForegroundActive = false;

    private static final class RuntimeConfigProbe {
        boolean valid = false;
        boolean hasTunInbound = false;
        String mixedListen = "";
        int mixedPort = -1;
        String error = "";
    }

    private static final class PortOwnerInfo {
        boolean occupied = false;
        String detail = "";
    }

    @Override
    public void onCreate() {
        super.onCreate();
        sAppContext = getApplicationContext();
        Log.i(TAG, "onCreate pid=" + android.os.Process.myPid() + " processUid=" + android.os.Process.myUid());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        final long startedAt = SystemClock.elapsedRealtime();
        final String action = intent != null ? safeString(intent.getAction()) : "";
        Log.i(TAG, "onStartCommand action=" + action
            + " flags=" + flags
            + " startId=" + startId
            + " running=" + sRunning
            + " runtimeAlive=" + isRuntimeProcessAlive()
            + " startQueued=" + sStartQueued.get()
            + " foregroundActive=" + mForegroundActive);
        if (ACTION_DISCONNECT.equals(action) || ACTION_STOP.equals(action)) {
            stopRuntime(true);
            stopSelf();
            logMainThreadDuration("onStartCommand/" + action, startedAt);
            return START_NOT_STICKY;
        }
        if (ACTION_RECONNECT.equals(action) || ACTION_RESTART.equals(action)) {
            final String executablePath = safeString(readPreference(PREF_LAST_EXECUTABLE_PATH));
            final String configPath = safeString(readPreference(PREF_LAST_CONFIG_PATH));
            final String workingDirectory = safeString(readPreference(PREF_LAST_WORKING_DIRECTORY));
            if (configPath.isEmpty()) {
                sLastError = "No saved VPN session is available to reconnect.";
                persistLastError(sLastError);
                stopSelf(startId);
                logMainThreadDuration("onStartCommand/" + action + "/missingConfig", startedAt);
                return START_NOT_STICKY;
            }

            stopRuntime(true);
            clearError();
            saveRuntimeLaunchConfig(executablePath, configPath, workingDirectory);
            ensureForegroundActive();
            enqueueStartRuntime(executablePath, configPath, workingDirectory);
            logMainThreadDuration("onStartCommand/" + action, startedAt);
            return START_STICKY;
        }
        if (ACTION_REFRESH_NETWORK_CACHE.equals(action)) {
            refreshAndroidNetworkState(getApplicationContext());
            final String executablePath = safeString(readPreference(PREF_LAST_EXECUTABLE_PATH));
            final String configPath = safeString(readPreference(PREF_LAST_CONFIG_PATH));
            final String workingDirectory = safeString(readPreference(PREF_LAST_WORKING_DIRECTORY));
            final boolean runtimeActive = isRuntimeProcessAlive() || sRunning || sStartQueued.get();
            if (runtimeActive && !configPath.isEmpty()) {
                appendRuntimeDiagnostic("Android network cache refresh: restarting VPN service network.");
                stopRuntime(false);
                clearError();
                saveRuntimeLaunchConfig(executablePath, configPath, workingDirectory);
                ensureForegroundActive();
                enqueueStartRuntime(executablePath, configPath, workingDirectory);
                logMainThreadDuration("onStartCommand/" + action + "/restart", startedAt);
                return START_STICKY;
            }

            appendRuntimeDiagnostic("Android network cache refresh: framework connectivity state refreshed.");
            logMainThreadDuration("onStartCommand/" + action, startedAt);
            return runtimeActive ? START_STICKY : START_NOT_STICKY;
        }
        final boolean runtimeAlive = isRuntimeProcessAlive();
        if (ACTION_QUERY_STATE.equals(action)) {
            if (runtimeAlive || sRunning) {
                sRunning = true;
                persistLastError("");
                ensureForegroundActive();
                startNotificationUpdates();
                logMainThreadDuration("onStartCommand/" + action, startedAt);
                return START_STICKY;
            }
            if (sStartQueued.get()) {
                persistLastError("");
                ensureForegroundActive();
                startNotificationUpdates();
                logMainThreadDuration("onStartCommand/" + action + "/queued", startedAt);
                return START_STICKY;
            }
            sRunning = false;
            persistLastError(sLastError);
            stopSelf(startId);
            logMainThreadDuration("onStartCommand/" + action, startedAt);
            return START_NOT_STICKY;
        }
        if (runtimeAlive) {
            sRunning = true;
            persistLastError("");
            ensureForegroundActive();
            startNotificationUpdates();
            logMainThreadDuration("onStartCommand/runtimeAlive", startedAt);
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
        ensureForegroundActive();
        enqueueStartRuntime(executablePath, configPath, workingDirectory);
        logMainThreadDuration("onStartCommand/connect", startedAt);
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "onDestroy running=" + sRunning
            + " runtimeAlive=" + isRuntimeProcessAlive()
            + " startQueued=" + sStartQueued.get());
        stopNotificationUpdates();
        if (!sRunning && !isRuntimeProcessAlive()) {
            stopRuntime(false);
        }
        super.onDestroy();
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        final boolean runtimeActive = sRunning || isRuntimeProcessAlive();
        final boolean startupPending = sStartQueued.get();
        Log.i(TAG, "onTaskRemoved runtimeActive=" + runtimeActive
            + " startupPending=" + startupPending
            + " foregroundActive=" + mForegroundActive);
        if (runtimeActive || startupPending) {
            terminateUiProcessAfterTaskRemoval();
            // Keep service alive and avoid expensive foreground refresh here:
            // this callback runs in app lifecycle churn where long main-thread work may ANR.
            return;
        }
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public void onRevoke() {
        sLastError = "Android VPN permission was revoked by the system.";
        persistLastError(sLastError);
        stopRuntime(false);
        stopSelf();
        super.onRevoke();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }

    public static boolean isRunning() {
        return sRunning;
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

    private void startRuntime(String executablePath, String configPath, String workingDirectory) {
        synchronized (mRuntimeLock) {
            if (isRuntimeProcessAlive()) {
                persistLastError("");
                appendRuntimeDiagnostic("Android runtime start skipped: an existing xray-core process is still alive.");
                return;
            }
            if (sRunning) {
                stopRuntime(false);
            }

            if (safeString(configPath).isEmpty()) {
                fail("Generated runtime config path is empty.");
                return;
            }

            clearRuntimeDiagnostics();
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
            final RuntimeConfigProbe configProbe = inspectRuntimeConfig(normalizedConfigPath);
            appendRuntimeDiagnostic("Android startup requested: sdk=" + Build.VERSION.SDK_INT
                + ", abis=" + supportedAbiSummary()
                + ", batteryOptimizationIgnored=" + isIgnoringBatteryOptimizations()
                + ", config=" + normalizedConfigPath
                + ", configExists=" + configFile.exists()
                + ", configSize=" + configFile.length()
                + ", tunRequested=" + requiresTunInbound);
            if (!configProbe.valid) {
                fail("Generated runtime config is invalid on Android: " + configProbe.error);
                return;
            }
            appendRuntimeDiagnostic("Config diagnostics: mixedListen=" + safeString(configProbe.mixedListen)
                + ", mixedPort=" + configProbe.mixedPort
                + ", tunInbound=" + configProbe.hasTunInbound);
            if (configProbe.mixedPort <= 0
                || !"127.0.0.1".equals(safeString(configProbe.mixedListen))) {
                fail("Generated runtime config must expose mixed inbound on 127.0.0.1 with a valid local port for Android TUN mode.");
                return;
            }
            if (requiresTunInbound && !configProbe.hasTunInbound) {
                fail("Generated runtime config is missing Android TUN inbound.");
                return;
            }
            final StringBuilder preflightPortError = new StringBuilder();
            final PortOwnerInfo preflightPortOwner = inspectLocalTcpPortOwner(configProbe.mixedPort);
            if (isLocalPortReachable(configProbe.mixedPort, preflightPortError)) {
                final String ownerDetail = safeString(preflightPortOwner.detail);
                fail("Local mixed proxy port 127.0.0.1:" + configProbe.mixedPort
                    + " is already occupied before xray-core launch"
                    + (ownerDetail.isEmpty() ? "." : ": " + ownerDetail));
                return;
            }
            appendRuntimeDiagnostic("Preflight port check: 127.0.0.1:" + configProbe.mixedPort
                + " was free before launch"
                + (safeString(preflightPortError.toString()).isEmpty() ? "." : " (" + preflightPortError + ")."));

            final String resolvedExecutablePath = resolveExecutablePath(requestedExecutablePath);
            appendRuntimeDiagnostic("Android ABI/core asset: abi=" + supportedAbiSummary()
                + ", resolvedAsset=" + safeString(sLastResolvedCoreAssetName));
            if (resolvedExecutablePath.isEmpty()) {
                fail("xray-core executable is missing on Android. Rebuild APK with bundled xray-core.");
                return;
            }

            final File executableFile = new File(resolvedExecutablePath);
            final boolean executableExists = executableFile.exists();
            final long executableSize = executableExists ? executableFile.length() : -1L;
            final boolean executableCanExecuteBefore = executableExists && executableFile.canExecute();
            if (!executableFile.exists()) {
                fail("xray-core executable is missing: " + resolvedExecutablePath);
                return;
            }
            appendRuntimeDiagnostic("Core selection: requestedPath=" + requestedExecutablePath
                + ", resolvedPath=" + resolvedExecutablePath
                + ", exists=" + executableExists
                + ", size=" + executableSize
                + ", canExecuteBeforeChmod=" + executableCanExecuteBefore);

            boolean chmodApplied = false;
            boolean chmodSucceeded = executableCanExecuteBefore;
            if (!executableCanExecuteBefore) {
                chmodApplied = !resolvedExecutablePath.endsWith(XRAY_NATIVE_LIB_NAME);
                chmodSucceeded = chmodApplied && executableFile.setExecutable(true, false);
                if (!chmodSucceeded) {
                    appendRuntimeDiagnostic("Core permission repair: chmodApplied=" + chmodApplied
                        + ", chmodSucceeded=false");
                    fail("xray-core binary is not executable: " + resolvedExecutablePath);
                    return;
                }
            }
            appendRuntimeDiagnostic("Core permission state: chmodApplied=" + chmodApplied
                + ", chmodSucceeded=" + chmodSucceeded
                + ", canExecuteAfterChmod=" + executableFile.canExecute());

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
                appendRuntimeDiagnostic("Android VPN interface established: tunFd=" + tunFd);
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
                appendRuntimeDiagnostic("Launching xray-core: workDir=" + effectiveWorkingDirectory
                    + ", mixedPort=" + configProbe.mixedPort
                    + ", tunMode=" + requiresTunInbound);
                sXrayProcess = processBuilder.start();
                appendRuntimeDiagnostic("xray-core process started: pid=" + processPid(sXrayProcess));
                if (requiresTunInbound) {
                    Log.i(TAG, "Started xray-core from: " + resolvedExecutablePath
                        + " (vpnFd=" + tunFd + ",xrayTunFd=" + tunFdForXray + ")");
                } else {
                    Log.i(TAG, "Started xray-core from: " + resolvedExecutablePath + " (proxy-only mode)");
                }
                startProcessMonitor(sXrayProcess);
            } catch (IOException exception) {
                final String startError = safeString(exception.getMessage());
                appendRuntimeDiagnostic("xray-core process start error: " + startError);
                fail("Failed to start xray-core on Android"
                    + (startError.isEmpty() ? "." : ": " + startError));
                return;
            } finally {
                restoreStdin(stdinBackup);
            }

            try {
                Thread.sleep(120L);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            }
            if (!isRuntimeProcessAlive()) {
                final String earlyFailure = safeString(sLastError);
                if (!earlyFailure.isEmpty()) {
                    fail(earlyFailure);
                } else {
                    fail("xray-core exited before binding the Android local proxy listener. "
                        + runtimeDiagnosticsSnapshot());
                }
                return;
            }

            sBaseUidRxBytes = uidRxBytes();
            sBaseUidTxBytes = uidTxBytes();
            writeLongPreference(PREF_BASE_UID_RX_BYTES, Math.max(0L, sBaseUidRxBytes));
            writeLongPreference(PREF_BASE_UID_TX_BYTES, Math.max(0L, sBaseUidTxBytes));
            sRunning = true;
            persistLastError("");
            startNotificationUpdates();
        }
    }

    private void enqueueStartRuntime(String executablePath, String configPath, String workingDirectory) {
        sStartCanceled.set(false);
        if (!sStartQueued.compareAndSet(false, true)) {
            Log.i(TAG, "Runtime start already queued; skipping duplicate start request.");
            return;
        }

        final String queuedExecutablePath = safeString(executablePath);
        final String queuedConfigPath = safeString(configPath);
        final String queuedWorkingDirectory = safeString(workingDirectory);
        sRuntimeExecutor.execute(() -> {
            try {
                if (sStartCanceled.get()) {
                    Log.i(TAG, "Skipping canceled runtime start request.");
                    return;
                }
                startRuntime(queuedExecutablePath, queuedConfigPath, queuedWorkingDirectory);
            } finally {
                sStartQueued.set(false);
            }
        });
    }

    private void stopRuntime(boolean userRequested) {
        synchronized (mRuntimeLock) {
            sStartCanceled.set(true);
            sRunning = false;
            stopNotificationUpdates();

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
            mForegroundActive = false;
            if (userRequested) {
                sLastError = "";
            }
            persistLastError(sLastError);
        }
    }

    private void startForegroundInternal() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mNotificationHandler.post(this::startForegroundInternal);
            return;
        }

        refreshForegroundNotification(true);
    }

    private void ensureForegroundActive() {
        if (mForegroundActive) {
            return;
        }
        startForegroundInternal();
    }

    private void startNotificationUpdates() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mNotificationHandler.post(this::startNotificationUpdates);
            return;
        }
        resetNotificationRateSamples();
        mNotificationHandler.removeCallbacks(mNotificationUpdater);
        mNotificationHandler.post(mNotificationUpdater);
    }

    private void stopNotificationUpdates() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mNotificationHandler.post(this::stopNotificationUpdates);
            return;
        }
        mNotificationHandler.removeCallbacks(mNotificationUpdater);
        resetNotificationRateSamples();
    }

    private void resetNotificationRateSamples() {
        mNotificationLastRxBytes = -1L;
        mNotificationLastTxBytes = -1L;
        mNotificationLastSampleElapsedMs = 0L;
        mNotificationLastDownBytesPerSec = 0L;
        mNotificationLastUpBytesPerSec = 0L;
    }

    private void ensureNotificationChannel(NotificationManager notificationManager) {
        if (notificationManager == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }

        final NotificationChannel channel = new NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "GenyConnect VPN status",
            NotificationManager.IMPORTANCE_DEFAULT
        );
        channel.setDescription("GenyConnect secure tunnel runtime");
        channel.setSound(null, null);
        channel.enableVibration(false);
        channel.enableLights(false);
        channel.setShowBadge(false);
        channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
        notificationManager.createNotificationChannel(channel);
    }

    private void refreshForegroundNotification(boolean forceStartForeground) {
        final long startedAt = SystemClock.elapsedRealtime();
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mNotificationHandler.post(() -> refreshForegroundNotification(forceStartForeground));
            return;
        }

        final NotificationManager notificationManager =
            (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (notificationManager == null) {
            return;
        }

        ensureNotificationChannel(notificationManager);

        final long totalRx = rxBytes();
        final long totalTx = txBytes();
        final long totalBytes = Math.max(0L, totalRx + totalTx);

        final long nowElapsedMs = SystemClock.elapsedRealtime();
        long downBytesPerSec = 0L;
        long upBytesPerSec = 0L;
        if (mNotificationLastSampleElapsedMs > 0L && nowElapsedMs > mNotificationLastSampleElapsedMs) {
            final long elapsedMs = nowElapsedMs - mNotificationLastSampleElapsedMs;
            if (elapsedMs >= MIN_RATE_SAMPLE_INTERVAL_MS) {
                long rxDelta = totalRx - mNotificationLastRxBytes;
                long txDelta = totalTx - mNotificationLastTxBytes;
                if (rxDelta < 0L) {
                    rxDelta = Math.max(0L, totalRx);
                }
                if (txDelta < 0L) {
                    txDelta = Math.max(0L, totalTx);
                }
                downBytesPerSec = Math.max(0L, Math.round((rxDelta * 1000.0) / Math.max(1L, elapsedMs)));
                upBytesPerSec = Math.max(0L, Math.round((txDelta * 1000.0) / Math.max(1L, elapsedMs)));
                mNotificationLastDownBytesPerSec = downBytesPerSec;
                mNotificationLastUpBytesPerSec = upBytesPerSec;
            } else {
                downBytesPerSec = mNotificationLastDownBytesPerSec;
                upBytesPerSec = mNotificationLastUpBytesPerSec;
            }
        } else {
            downBytesPerSec = mNotificationLastDownBytesPerSec;
            upBytesPerSec = mNotificationLastUpBytesPerSec;
        }
        mNotificationLastRxBytes = totalRx;
        mNotificationLastTxBytes = totalTx;
        mNotificationLastSampleElapsedMs = nowElapsedMs;

        final Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            ? new Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            : new Notification.Builder(this);

        final Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent contentIntent = null;
        if (launchIntent != null) {
            final int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                : PendingIntent.FLAG_UPDATE_CURRENT;
            contentIntent = PendingIntent.getActivity(this, 0, launchIntent, flags);
        }

        final String status = (sRunning || isRuntimeProcessAlive()) ? "Connected" : "Starting";
        final String downText = formatSpeed(downBytesPerSec);
        final String upText = formatSpeed(upBytesPerSec);
        final String totalText = formatBytes(totalBytes);
        final String titleText = "GenyConnect";
        final String proxyText = "proxy • " + upText + "↑  " + downText + "↓";
        final String directText = "direct • 0 B/s↑  0 B/s↓";
        final String summaryText = status + " • Total " + totalText;
        final String expandedText = proxyText
            + "\n" + directText
            + "\n" + summaryText;
        builder
            .setContentTitle(titleText)
            .setContentText(proxyText)
            .setSubText(summaryText)
            .setStyle(new Notification.BigTextStyle()
                .setBigContentTitle(titleText)
                .bigText(expandedText)
                .setSummaryText(summaryText))
            .setSmallIcon(R.drawable.ic_notification_status)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setPriority(Notification.PRIORITY_DEFAULT)
            .setDefaults(0)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setColor(0xFF0EA5E9)
            .setShowWhen(false)
            .setVisibility(Notification.VISIBILITY_PUBLIC);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE);
        }

        if (mNotificationLargeIcon == null) {
            mNotificationLargeIcon = BitmapFactory.decodeResource(getResources(), R.drawable.ic_launcher_foreground);
        }
        if (mNotificationLargeIcon != null) {
            builder.setLargeIcon(mNotificationLargeIcon);
        }

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent);
        }

        final boolean runtimeActive = sRunning || isRuntimeProcessAlive();
        final boolean restartAllowed = runtimeActive && !sStartQueued.get() && hasSavedRuntimeLaunchConfig();
        final PendingIntent disconnectIntent = buildServiceActionPendingIntent(ACTION_DISCONNECT, 1001);
        if (disconnectIntent != null) {
            builder.addAction(
                android.R.drawable.ic_media_pause,
                NOTIFICATION_ACTION_DISCONNECT_LABEL,
                disconnectIntent);
        }
        if (restartAllowed) {
            final PendingIntent reconnectIntent = buildServiceActionPendingIntent(ACTION_RECONNECT, 1002);
            if (reconnectIntent != null) {
                builder.addAction(
                    android.R.drawable.ic_popup_sync,
                    NOTIFICATION_ACTION_RECONNECT_LABEL,
                    reconnectIntent);
            }
        }

        final Notification notification = builder.build();
        if (forceStartForeground || !mForegroundActive) {
            startForeground(NOTIFICATION_ID, notification);
            mForegroundActive = true;
        } else {
            notificationManager.notify(NOTIFICATION_ID, notification);
        }
        logMainThreadDuration("refreshForegroundNotification(force=" + forceStartForeground + ")", startedAt);
    }

    private PendingIntent buildServiceActionPendingIntent(String action, int requestCode) {
        final String normalizedAction = safeString(action);
        if (normalizedAction.isEmpty()) {
            return null;
        }

        final Intent intent = new Intent(this, GenyConnectVpnService.class);
        intent.setAction(normalizedAction);
        final int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
            ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            : PendingIntent.FLAG_UPDATE_CURRENT;
        return PendingIntent.getService(this, requestCode, intent, flags);
    }

    private static String formatBytes(long bytes) {
        final long safe = Math.max(0L, bytes);
        final String[] units = new String[] {"B", "KB", "MB", "GB", "TB"};
        double value = (double) safe;
        int index = 0;
        while (value >= 1024.0 && index < units.length - 1) {
            value = value / 1024.0;
            index += 1;
        }
        final int decimals = index == 0 ? 0 : (value >= 100.0 ? 0 : (value >= 10.0 ? 1 : 2));
        return String.format(Locale.US, "%." + decimals + "f %s", value, units[index]);
    }

    private static String formatSpeed(long bytesPerSec) {
        final long safe = Math.max(0L, bytesPerSec);
        if (safe == 0L) {
            return "0 B/s";
        }
        return formatBytes(safe) + "/s";
    }

    private static String safeString(String value) {
        return value == null ? "" : value.trim();
    }

    static void refreshAndroidNetworkState(Context context) {
        if (context == null) {
            return;
        }
        try {
            final ConnectivityManager manager =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (manager == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                return;
            }

            final Network activeNetwork = manager.getActiveNetwork();
            manager.reportNetworkConnectivity(activeNetwork, false);
            manager.reportNetworkConnectivity(activeNetwork, true);
            manager.bindProcessToNetwork(null);
        } catch (Exception exception) {
            Log.w(TAG, "Android network state refresh failed: " + exception.getMessage());
        }
    }

    private static void clearRuntimeDiagnostics() {
        synchronized (sDiagnosticsLock) {
            sRuntimeDiagnosticHistory.clear();
            sLastRuntimeDiagnostics = "";
        }
    }

    private static void appendRuntimeDiagnostic(String line) {
        final String normalized = safeString(line);
        if (normalized.isEmpty()) {
            return;
        }
        synchronized (sDiagnosticsLock) {
            sRuntimeDiagnosticHistory.addLast(normalized);
            while (sRuntimeDiagnosticHistory.size() > DIAGNOSTIC_HISTORY_LIMIT) {
                sRuntimeDiagnosticHistory.removeFirst();
            }
            sLastRuntimeDiagnostics = normalized;
        }
        Log.i(TAG, normalized);
    }

    private static String runtimeDiagnosticsSnapshot() {
        synchronized (sDiagnosticsLock) {
            if (sRuntimeDiagnosticHistory.isEmpty()) {
                return safeString(sLastRuntimeDiagnostics);
            }
            final StringBuilder joined = new StringBuilder(256);
            for (String item : sRuntimeDiagnosticHistory) {
                if (joined.length() > 0) {
                    joined.append(" | ");
                }
                joined.append(item);
            }
            return joined.toString();
        }
    }

    private static String supportedAbiSummary() {
        if (Build.SUPPORTED_ABIS == null || Build.SUPPORTED_ABIS.length == 0) {
            return safeString(Build.CPU_ABI);
        }
        final StringBuilder joined = new StringBuilder(64);
        for (String abi : Build.SUPPORTED_ABIS) {
            final String normalized = safeString(abi);
            if (normalized.isEmpty()) {
                continue;
            }
            if (joined.length() > 0) {
                joined.append(',');
            }
            joined.append(normalized);
        }
        return joined.toString();
    }

    private boolean isIgnoringBatteryOptimizations() {
        try {
            final PowerManager powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
            return powerManager != null && powerManager.isIgnoringBatteryOptimizations(getPackageName());
        } catch (Exception ignored) {
            return false;
        }
    }

    private boolean isLocalPortReachable(int port, StringBuilder detailOut) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", port), 220);
            return true;
        } catch (Exception exception) {
            if (detailOut != null) {
                detailOut.setLength(0);
                detailOut.append(safeString(exception.getMessage()));
            }
            return false;
        }
    }

    private static long processPid(Process process) {
        if (process == null) {
            return -1L;
        }
        try {
            final Method pidMethod = Process.class.getMethod("pid");
            final Object value = pidMethod.invoke(process);
            if (value instanceof Number) {
                return ((Number) value).longValue();
            }
        } catch (Exception ignored) {
        }
        return -1L;
    }

    private static PortOwnerInfo inspectLocalTcpPortOwner(int port) {
        final PortOwnerInfo info = new PortOwnerInfo();
        if (port <= 0 || port > 65535) {
            return info;
        }
        final String inode = findListeningTcpInode(port);
        if (inode.isEmpty()) {
            info.detail = "no /proc TCP listener inode was visible for port " + port;
            return info;
        }

        info.occupied = true;
        final String processDetail = findProcessForSocketInode(inode);
        info.detail = processDetail.isEmpty()
            ? "listener inode=" + inode + " (process owner unavailable; Android /proc access may be restricted)"
            : "listener inode=" + inode + ", " + processDetail;
        return info;
    }

    private static String findListeningTcpInode(int port) {
        final String tcp4 = findListeningTcpInodeInFile("/proc/net/tcp", port);
        if (!tcp4.isEmpty()) {
            return tcp4;
        }
        return findListeningTcpInodeInFile("/proc/net/tcp6", port);
    }

    private static String findListeningTcpInodeInFile(String path, int port) {
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = reader.readLine()) != null) {
                final String trimmed = safeString(line);
                if (trimmed.isEmpty() || trimmed.startsWith("sl")) {
                    continue;
                }
                final String[] parts = trimmed.split("\\s+");
                if (parts.length <= 9) {
                    continue;
                }
                final String[] addressParts = parts[1].split(":");
                if (addressParts.length != 2) {
                    continue;
                }
                int parsedPort = -1;
                try {
                    parsedPort = Integer.parseInt(addressParts[1], 16);
                } catch (Exception ignored) {
                }
                if (parsedPort != port) {
                    continue;
                }
                final String state = parts[3];
                if (!"0A".equalsIgnoreCase(state)) {
                    continue;
                }
                return safeString(parts[9]);
            }
        } catch (Exception ignored) {
        }
        return "";
    }

    private static String findProcessForSocketInode(String inode) {
        final String socketNeedle = "socket:[" + safeString(inode) + "]";
        if (socketNeedle.length() <= "socket:[]".length()) {
            return "";
        }
        final File procDir = new File("/proc");
        final File[] entries = procDir.listFiles();
        if (entries == null) {
            return "";
        }
        for (File entry : entries) {
            final String pidText = entry.getName();
            int pid = -1;
            try {
                pid = Integer.parseInt(pidText);
            } catch (Exception ignored) {
                continue;
            }
            final File fdDir = new File(entry, "fd");
            final File[] fds = fdDir.listFiles();
            if (fds == null) {
                continue;
            }
            for (File fd : fds) {
                try {
                    final String target = Os.readlink(fd.getAbsolutePath());
                    if (socketNeedle.equals(target)) {
                        final String cmdline = readProcessCmdline(pid);
                        return "pid=" + pid + (cmdline.isEmpty() ? "" : ", cmdline=" + cmdline);
                    }
                } catch (Exception ignored) {
                }
            }
        }
        return "";
    }

    private static android.content.SharedPreferences prefs() {
        Context appContext = sAppContext;
        if (appContext == null) {
            appContext = AndroidRuntimeBridge.appContext();
        }
        if (appContext == null) {
            return null;
        }
        return appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    private static String readPreference(String key) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return "";
        }
        return safeString(sharedPreferences.getString(key, ""));
    }

    private static long readLongPreference(String key, long fallback) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return fallback;
        }
        return sharedPreferences.getLong(key, fallback);
    }

    private static int readIntPreference(String key, int fallback) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return fallback;
        }
        return sharedPreferences.getInt(key, fallback);
    }

    private static boolean isRuntimeProcessAlive() {
        if (sXrayProcess == null) {
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

    private static void writeLongPreference(String key, long value) {
        final android.content.SharedPreferences sharedPreferences = prefs();
        if (sharedPreferences == null) {
            return;
        }
        sharedPreferences.edit().putLong(key, value).commit();
    }

    private void terminateUiProcessAfterTaskRemoval() {
        final UiProcessState state = readUiProcessState();
        final int uiPid = state.valid ? state.pid : readIntPreference(PREF_UI_PROCESS_PID, -1);
        final long updatedAtMs = state.valid
            ? state.updatedAtMs
            : readLongPreference(PREF_UI_PROCESS_UPDATED_AT_MS, 0L);
        final int selfPid = android.os.Process.myPid();
        if (uiPid <= 0 || uiPid == selfPid) {
            return;
        }
        if (updatedAtMs > 0L && Math.abs(System.currentTimeMillis() - updatedAtMs) > 7L * 24L * 60L * 60L * 1000L) {
            Log.i(TAG, "Skipping stale UI process cleanup after task removal: pid=" + uiPid);
            return;
        }

        final String cmdline = readProcessCmdline(uiPid);
        if (!getPackageName().equals(cmdline)) {
            Log.i(TAG, "Skipping UI process cleanup after task removal: pid=" + uiPid
                + " cmdline=" + cmdline);
            return;
        }

        Log.i(TAG, "Terminating UI process after task removal: pid=" + uiPid
            + " while keeping VPN service pid=" + selfPid);
        android.os.Process.killProcess(uiPid);
    }

    private static UiProcessState readUiProcessState() {
        Context appContext = sAppContext;
        if (appContext == null) {
            appContext = AndroidRuntimeBridge.appContext();
        }
        if (appContext == null) {
            return UiProcessState.invalid();
        }

        final File stateFile = new File(appContext.getNoBackupFilesDir(), UI_PROCESS_STATE_FILE);
        try (BufferedReader reader = new BufferedReader(new FileReader(stateFile))) {
            final String pidLine = reader.readLine();
            final String updatedAtLine = reader.readLine();
            if (pidLine == null || updatedAtLine == null) {
                return UiProcessState.invalid();
            }
            return new UiProcessState(Integer.parseInt(pidLine.trim()),
                Long.parseLong(updatedAtLine.trim()));
        } catch (Exception ignored) {
            return UiProcessState.invalid();
        }
    }

    private static final class UiProcessState {
        final boolean valid;
        final int pid;
        final long updatedAtMs;

        UiProcessState(int pid, long updatedAtMs) {
            this.valid = pid > 0;
            this.pid = pid;
            this.updatedAtMs = updatedAtMs;
        }

        private UiProcessState() {
            this.valid = false;
            this.pid = -1;
            this.updatedAtMs = 0L;
        }

        static UiProcessState invalid() {
            return new UiProcessState();
        }
    }

    private static String readProcessCmdline(int pid) {
        if (pid <= 0) {
            return "";
        }
        final File cmdlineFile = new File("/proc/" + pid + "/cmdline");
        final StringBuilder content = new StringBuilder(128);
        try (FileReader fileReader = new FileReader(cmdlineFile)) {
            int value;
            while ((value = fileReader.read()) >= 0 && content.length() < 128) {
                content.append(value == 0 ? ' ' : (char) value);
            }
        } catch (Exception ignored) {
            return "";
        }
        return content.toString().trim();
    }

    private static void logMainThreadDuration(String section, long startedAtElapsedMs) {
        final long elapsed = SystemClock.elapsedRealtime() - Math.max(0L, startedAtElapsedMs);
        if (elapsed >= MAIN_THREAD_WARNING_MS) {
            Log.w(TAG, section + " main-thread duration=" + elapsed + "ms");
        }
    }

    private static void saveRuntimeLaunchConfig(String executablePath, String configPath, String workingDirectory) {
        writePreference(PREF_LAST_EXECUTABLE_PATH, executablePath);
        writePreference(PREF_LAST_CONFIG_PATH, configPath);
        writePreference(PREF_LAST_WORKING_DIRECTORY, workingDirectory);
    }

    private static boolean hasSavedRuntimeLaunchConfig() {
        return !safeString(readPreference(PREF_LAST_CONFIG_PATH)).isEmpty();
    }

    private static void persistLastError(String errorText) {
        writePreference(PREF_LAST_ERROR, errorText);
    }

    static boolean runtimeActiveInProcess() {
        return isRuntimeProcessAlive() || sRunning;
    }

    static boolean sessionRunningInProcess() {
        return sRunning;
    }

    static boolean startupPendingInProcess() {
        return sStartQueued.get();
    }

    static boolean runtimeProcessAliveInProcess() {
        return isRuntimeProcessAlive();
    }

    static long rxBytesInProcess() {
        final long current = uidRxBytes();
        if (current < 0L || !runtimeActiveInProcess() || sBaseUidRxBytes <= 0L) {
            return 0L;
        }
        return Math.max(0L, current - sBaseUidRxBytes);
    }

    static long txBytesInProcess() {
        final long current = uidTxBytes();
        if (current < 0L || !runtimeActiveInProcess() || sBaseUidTxBytes <= 0L) {
            return 0L;
        }
        return Math.max(0L, current - sBaseUidTxBytes);
    }

    static String lastErrorInProcess() {
        return safeString(sLastError);
    }

    static String lastDiagnosticsInProcess() {
        final String diagnostics = runtimeDiagnosticsSnapshot();
        if (!diagnostics.isEmpty()) {
            return diagnostics;
        }
        return safeString(sLastError);
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

    private RuntimeConfigProbe inspectRuntimeConfig(String configPath) {
        final RuntimeConfigProbe probe = new RuntimeConfigProbe();
        final String path = safeString(configPath);
        if (path.isEmpty()) {
            probe.error = "runtime config path is empty";
            return probe;
        }

        final StringBuilder payload = new StringBuilder(32 * 1024);
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = reader.readLine()) != null) {
                payload.append(line);
            }
        } catch (Exception exception) {
            probe.error = "failed to read config: " + safeString(exception.getMessage());
            return probe;
        }

        try {
            final JSONObject root = new JSONObject(payload.toString());
            final JSONArray inbounds = root.optJSONArray("inbounds");
            if (inbounds != null) {
                for (int i = 0; i < inbounds.length(); ++i) {
                    final JSONObject inbound = inbounds.optJSONObject(i);
                    if (inbound == null) {
                        continue;
                    }
                    final String protocol = safeString(inbound.optString("protocol"));
                    if ("mixed".equalsIgnoreCase(protocol) && probe.mixedPort <= 0) {
                        probe.mixedListen = safeString(inbound.optString("listen"));
                        probe.mixedPort = inbound.optInt("port", -1);
                    } else if ("tun".equalsIgnoreCase(protocol)) {
                        probe.hasTunInbound = true;
                    }
                }
            }
            probe.valid = true;
            return probe;
        } catch (Exception exception) {
            probe.error = "invalid JSON: " + safeString(exception.getMessage());
            return probe;
        }
    }

    private String resolveExecutablePath(String requestedExecutablePath) {
        sLastResolvedCoreAssetName = "";
        final String nativeLibPath = resolveNativeLibraryExecutablePath();
        if (!nativeLibPath.isEmpty()) {
            sLastResolvedCoreAssetName = XRAY_NATIVE_LIB_NAME;
            appendRuntimeDiagnostic("Using native library xray executable: " + nativeLibPath);
            return nativeLibPath;
        }

        if (!requestedExecutablePath.isEmpty()) {
            final File requestedFile = new File(requestedExecutablePath);
            if (requestedFile.exists()) {
                sLastResolvedCoreAssetName = "requested:" + requestedFile.getName();
                appendRuntimeDiagnostic("Using requested xray executable fallback: " + requestedFile.getAbsolutePath());
                return requestedFile.getAbsolutePath();
            }
            appendRuntimeDiagnostic("Requested xray path is missing; falling back to bundled asset: " + requestedExecutablePath);
        }

        final String extractedPath = extractBundledXrayAsset();
        if (!extractedPath.isEmpty()) {
            appendRuntimeDiagnostic("Using extracted asset xray executable fallback: " + extractedPath);
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
        final Set<String> candidateAssets = new LinkedHashSet<>();
        if (Build.SUPPORTED_ABIS != null) {
            for (String abi : Build.SUPPORTED_ABIS) {
                final String normalizedAbi = safeString(abi);
                if (!normalizedAbi.isEmpty()) {
                    candidateAssets.add(XRAY_ASSET_DIR + "/" + normalizedAbi + "/xray");
                }
            }
        }
        candidateAssets.add(XRAY_ASSET_ROOT_NAME);
        candidateAssets.add(XRAY_ASSET_LEGACY_NAME);

        for (String assetPath : candidateAssets) {
            final String extracted = extractBundledXrayAssetFromPath(assetPath);
            if (!extracted.isEmpty()) {
                sLastResolvedCoreAssetName = assetPath;
                appendRuntimeDiagnostic("Extracted xray-core asset from: " + assetPath);
                return extracted;
            }
        }
        appendRuntimeDiagnostic("No bundled xray-core asset candidate could be extracted.");
        return "";
    }

    private String extractBundledXrayAssetFromPath(String assetPath) {
        final String normalizedAssetPath = safeString(assetPath);
        if (normalizedAssetPath.isEmpty()) {
            return "";
        }

        final File runtimeDir = new File(getFilesDir(), "runtime");
        if (!runtimeDir.exists() && !runtimeDir.mkdirs()) {
            Log.e(TAG, "Failed to create runtime directory: " + runtimeDir.getAbsolutePath());
            return "";
        }

        final File outFile = new File(runtimeDir, XRAY_RUNTIME_FILE);
        try (InputStream input = getAssets().open(normalizedAssetPath);
             FileOutputStream output = new FileOutputStream(outFile, false)) {
            final byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                output.write(buffer, 0, read);
            }
            output.flush();
        } catch (IOException exception) {
            Log.w(TAG, "Bundled xray-core asset is unavailable at '" + normalizedAssetPath + "': "
                + exception.getMessage());
            return "";
        }

        if (!outFile.canExecute() && !outFile.setExecutable(true, false)) {
            Log.e(TAG, "Failed to mark bundled xray-core executable: " + outFile.getAbsolutePath());
            return "";
        }

        appendRuntimeDiagnostic("Bundled asset extracted to " + outFile.getAbsolutePath()
            + " size=" + outFile.length()
            + " canExecute=" + outFile.canExecute());

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
                        appendRuntimeDiagnostic("xray-core stdout/stderr: " + lastLine);
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

            synchronized (mRuntimeLock) {
                if (sXrayProcess != process) {
                    return;
                }
                final boolean exitedDuringStartup = !sRunning;
                final String exitStatus = "normal";
                appendRuntimeDiagnostic("xray-core exited: exitCode=" + exitCode
                    + ", exitStatus=" + exitStatus
                    + (lastLine.isEmpty() ? "" : ", lastOutput=" + lastLine));
                if (lastLine.isEmpty()) {
                    final String diagnostics = runtimeDiagnosticsSnapshot();
                    sLastError = diagnostics.isEmpty()
                        ? "xray-core exited "
                            + (exitedDuringStartup ? "before listener readiness" : "unexpectedly")
                            + " with code " + exitCode + "."
                        : "xray-core exited "
                            + (exitedDuringStartup ? "before listener readiness" : "unexpectedly")
                            + " with code " + exitCode + ": " + diagnostics;
                } else {
                    sLastError = "xray-core exited "
                        + (exitedDuringStartup ? "before listener readiness" : "unexpectedly")
                        + " with code " + exitCode + ": " + lastLine;
                }
                Log.e(TAG, sLastError);
                if (sRunning) {
                    stopRuntime(false);
                    stopSelf();
                } else {
                    sXrayProcess = null;
                    persistLastError(sLastError);
                }
            }
        }, "genyconnect-xray-monitor");
        monitor.setDaemon(true);
        monitor.start();
    }

    private void clearError() {
        sLastError = "";
    }

    private void fail(String message) {
        final String normalized = message == null ? "Unknown Android runtime failure." : message.trim();
        final String diagnostics = runtimeDiagnosticsSnapshot();
        if (!diagnostics.isEmpty() && !diagnostics.contains(normalized)) {
            sLastError = normalized + " | " + diagnostics;
        } else {
            sLastError = normalized;
        }
        appendRuntimeDiagnostic("Startup failure: " + normalized);
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
