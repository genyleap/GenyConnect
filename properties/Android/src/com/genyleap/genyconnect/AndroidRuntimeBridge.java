package com.genyleap.genyconnect;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.database.Cursor;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.VpnService;
import android.os.BatteryManager;
import android.os.Build;
import android.os.SystemClock;
import android.os.PowerManager;
import android.provider.Settings;
import android.content.SharedPreferences;
import android.view.Window;
import android.view.WindowManager;
import androidx.core.content.FileProvider;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;

import org.json.JSONArray;
import org.json.JSONObject;

public final class AndroidRuntimeBridge {
    private static final String TAG = "AndroidRuntimeBridge";
    private static final String PERMISSION_PROMPT_LAUNCHED =
        "Android VPN permission is required. Grant it and tap Connect again.";
    private static final String PREFS_NAME = "genyconnect_vpn";
    private static final String PREF_PROMPT_AT_MS = "prompt_at_ms";
    private static final String PREF_PROMPT_COUNT = "prompt_count";
    private static final String VPN_STATE_AUTHORITY_SUFFIX = ".vpnstate";
    private static final String VPN_STATE_PATH = "state";
    private static final long STATE_QUERY_TIMEOUT_MS = 250L;
    private static final long STATE_CACHE_TTL_MS = 150L;
    private static final long STATE_STALE_FALLBACK_MS = 2500L;
    private static final AtomicBoolean STATE_QUERY_IN_FLIGHT = new AtomicBoolean(false);
    private static final ThreadLocal<Boolean> IN_STATE_QUERY = new ThreadLocal<>();
    private static final ExecutorService STATE_QUERY_EXECUTOR = Executors.newSingleThreadExecutor(
        new ThreadFactory() {
            @Override
            public Thread newThread(Runnable runnable) {
                final Thread thread = new Thread(runnable, "GenyConnectVpnStateQuery");
                thread.setDaemon(true);
                return thread;
            }
        });
    private static volatile RuntimeState sCachedRuntimeState = new RuntimeState();

    private AndroidRuntimeBridge() {
    }

    private static void showSystemBars(Window window) {
        if (window == null) {
            return;
        }

        WindowCompat.setDecorFitsSystemWindows(window, true);
        final WindowInsetsControllerCompat controller =
            WindowCompat.getInsetsController(window, window.getDecorView());
        if (controller != null) {
            controller.show(WindowInsetsCompat.Type.systemBars());
        }
    }

    private static void applySystemBarAppearance(Window window, boolean darkThemeEnabled) {
        if (window == null) {
            return;
        }

        WindowCompat.setDecorFitsSystemWindows(window, true);
        final WindowInsetsControllerCompat controller =
            WindowCompat.getInsetsController(window, window.getDecorView());
        if (controller == null) {
            return;
        }

        final boolean lightBarIcons = !darkThemeEnabled;
        controller.setAppearanceLightStatusBars(lightBarIcons);
        controller.setAppearanceLightNavigationBars(lightBarIcons);
        controller.show(WindowInsetsCompat.Type.systemBars());
    }

    private static final class RuntimeState {
        boolean valid = false;
        boolean running = false;
        long rxBytes = 0L;
        long txBytes = 0L;
        String lastError = "";
        long queriedElapsedMs = 0L;
        boolean startupPending = false;
        boolean runtimeAlive = false;

        RuntimeState copy() {
            final RuntimeState copy = new RuntimeState();
            copy.valid = valid;
            copy.running = running;
            copy.rxBytes = rxBytes;
            copy.txBytes = txBytes;
            copy.lastError = lastError;
            copy.queriedElapsedMs = queriedElapsedMs;
            copy.startupPending = startupPending;
            copy.runtimeAlive = runtimeAlive;
            return copy;
        }
    }

    private static Context context() {
        try {
            final Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
            final Object application = activityThreadClass.getMethod("currentApplication").invoke(null);
            if (application instanceof Context) {
                return (Context) application;
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    static Context appContext() {
        return context();
    }

    private static Activity activity() {
        try {
            final Class<?> qtNativeClass = Class.forName("org.qtproject.qt.android.QtNative");
            final Method activityMethod = qtNativeClass.getDeclaredMethod("activity");
            activityMethod.setAccessible(true);
            final Object qtActivity = activityMethod.invoke(null);
            if (qtActivity instanceof Activity) {
                return (Activity) qtActivity;
            }
        } catch (Exception ignored) {
        }

        final Context context = context();
        if (context instanceof Activity) {
            return (Activity) context;
        }
        return null;
    }

    private static void ensureStandardSystemUi(Activity currentActivity) {
        if (currentActivity == null) {
            return;
        }

        currentActivity.runOnUiThread(() -> {
            try {
                final Window window = currentActivity.getWindow();
                if (window == null) {
                    return;
                }
                window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
                showSystemBars(window);
            } catch (Exception ignored) {
            }
        });
    }

    private static String launchVpnPermissionUi(Intent permissionIntent) {
        final Activity currentActivity = activity();
        if (currentActivity != null) {
            try {
                final CountDownLatch latch = new CountDownLatch(1);
                final String[] errorHolder = new String[] {""};
                currentActivity.runOnUiThread(() -> {
                    try {
                        currentActivity.startActivityForResult(permissionIntent, 43171);
                    } catch (Exception exception) {
                        errorHolder[0] = "Failed to open Android VPN permission dialog: " + exception.getMessage();
                    } finally {
                        latch.countDown();
                    }
                });
                final boolean launchedOnUi = latch.await(3, TimeUnit.SECONDS);
                if (!launchedOnUi) {
                    return "Failed to open Android VPN permission dialog: UI thread timeout while launching prompt.";
                }
                if (!safeString(errorHolder[0]).isEmpty()) {
                    return errorHolder[0];
                }
                return "";
            } catch (Exception exception) {
                return "Failed to launch Android VPN permission dialog: " + exception.getMessage();
            }
        }

        final Context appContext = context();
        if (appContext != null) {
            try {
                permissionIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                appContext.startActivity(permissionIntent);
                return "";
            } catch (Exception exception) {
                try {
                    final Intent settingsIntent = new Intent(Settings.ACTION_VPN_SETTINGS);
                    settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    appContext.startActivity(settingsIntent);
                    return "Android VPN permission screen did not open directly. Open VPN settings, allow GenyConnect, then tap Connect again.";
                } catch (Exception settingsException) {
                    return "Failed to open Android VPN permission UI: " + exception.getMessage();
                }
            }
        }

        return "Android runtime context is unavailable.";
    }

    private static boolean openVpnSettings(Context appContext) {
        if (appContext == null) {
            return false;
        }
        try {
            final Intent settingsIntent = new Intent(Settings.ACTION_VPN_SETTINGS);
            settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            appContext.startActivity(settingsIntent);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static SharedPreferences prefs(Context context) {
        if (context == null) {
            return null;
        }
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    private static long getPromptAtMs(SharedPreferences prefs) {
        return prefs == null ? 0L : prefs.getLong(PREF_PROMPT_AT_MS, 0L);
    }

    private static int getPromptCount(SharedPreferences prefs) {
        return prefs == null ? 0 : prefs.getInt(PREF_PROMPT_COUNT, 0);
    }

    private static void savePromptState(SharedPreferences prefs, long atMs, int count) {
        if (prefs == null) {
            return;
        }
        prefs.edit()
            .putLong(PREF_PROMPT_AT_MS, atMs)
            .putInt(PREF_PROMPT_COUNT, count)
            .apply();
    }

    private static void clearPromptState(SharedPreferences prefs) {
        if (prefs == null) {
            return;
        }
        prefs.edit()
            .remove(PREF_PROMPT_AT_MS)
            .remove(PREF_PROMPT_COUNT)
            .apply();
    }

    public static String connect(String executablePath, String configPath, String workingDirectory) {
        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context permissionContext = currentActivity != null ? currentActivity : appContext;
        if (permissionContext == null) {
            return "Android runtime context is unavailable.";
        }
        final SharedPreferences preferences = prefs(permissionContext);
        final boolean requiresTunPermission = configRequestsTun(configPath);
        if (requiresTunPermission) {
            final Intent permissionIntent = VpnService.prepare(permissionContext);
            if (permissionIntent != null) {
                final long lastPromptAt = getPromptAtMs(preferences);
                final int promptCount = getPromptCount(preferences);
                final long now = System.currentTimeMillis();
                if (lastPromptAt > 0L && (now - lastPromptAt) < 1200L) {
                    return "Android VPN permission prompt is already pending. Complete it, then tap Connect again. [attempt="
                        + promptCount + ",activity=" + (currentActivity != null) + "]";
                }

                if (promptCount >= 1 && openVpnSettings(permissionContext)) {
                    savePromptState(preferences, now, promptCount + 1);
                    return "Android VPN permission is still not granted. Opened VPN settings; allow GenyConnect, then tap Connect again. [attempt="
                        + (promptCount + 1) + ",activity=" + (currentActivity != null) + "]";
                }

                final String launchError = launchVpnPermissionUi(permissionIntent);
                if (!launchError.isEmpty()) {
                    return launchError;
                }
                savePromptState(preferences, now, promptCount + 1);
                return PERMISSION_PROMPT_LAUNCHED + " [attempt=" + (promptCount + 1)
                    + ",activity=" + (currentActivity != null) + "]";
            }
            clearPromptState(preferences);
        } else {
            clearPromptState(preferences);
        }

        final Context serviceContext = appContext != null ? appContext : permissionContext;
        final Intent startIntent = new Intent(serviceContext, GenyConnectVpnService.class);
        startIntent.setAction(GenyConnectVpnService.ACTION_CONNECT);
        startIntent.putExtra(GenyConnectVpnService.EXTRA_EXECUTABLE_PATH, safeString(executablePath));
        startIntent.putExtra(GenyConnectVpnService.EXTRA_CONFIG_PATH, safeString(configPath));
        startIntent.putExtra(GenyConnectVpnService.EXTRA_WORKING_DIRECTORY, safeString(workingDirectory));

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                serviceContext.startForegroundService(startIntent);
            } else {
                serviceContext.startService(startIntent);
            }
        } catch (Exception exception) {
            return "Failed to start Android VPN service: " + exception.getMessage();
        }

        return "";
    }

    public static String disconnect() {
        final Context context = context();
        if (context == null) {
            return "Android runtime context is unavailable.";
        }

        final Intent stopIntent = new Intent(context, GenyConnectVpnService.class);
        stopIntent.setAction(GenyConnectVpnService.ACTION_DISCONNECT);
        try {
            context.startService(stopIntent);
        } catch (Exception exception) {
            return "Failed to stop Android VPN service: " + exception.getMessage();
        }

        return "";
    }

    public static String clearNetworkCache() {
        final JSONObject result = new JSONObject();
        final JSONArray details = new JSONArray();
        try {
            final Context appContext = context();
            if (appContext == null) {
                result.put("ok", false);
                result.put("message", "Android runtime context is unavailable.");
                result.put("details", details);
                return result.toString();
            }

            final ConnectivityManager manager =
                (ConnectivityManager) appContext.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (manager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                final Network activeNetwork = manager.getActiveNetwork();
                manager.reportNetworkConnectivity(activeNetwork, false);
                manager.reportNetworkConnectivity(activeNetwork, true);
                manager.bindProcessToNetwork(null);
                details.put("Framework connectivity state re-evaluated with ConnectivityManager.");
            } else {
                details.put("ConnectivityManager refresh is unavailable on this Android API level.");
            }

            final boolean runtimeActive = isRunning() || isRuntimeAlive() || isStartupPending();
            if (runtimeActive) {
                final Intent refreshIntent = new Intent(appContext, GenyConnectVpnService.class);
                refreshIntent.setAction(GenyConnectVpnService.ACTION_REFRESH_NETWORK_CACHE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    appContext.startForegroundService(refreshIntent);
                } else {
                    appContext.startService(refreshIntent);
                }
                details.put("GenyConnect VPN service requested to rebuild its VPN network.");
                result.put("ok", true);
                result.put("message", "Android VPN network cache refresh started.");
            } else {
                GenyConnectVpnService.refreshAndroidNetworkState(appContext);
                result.put("ok", true);
                result.put("message", "Android framework network state was refreshed. Start the VPN to rebuild the GenyConnect tunnel network.");
            }
            result.put("details", details);
            return result.toString();
        } catch (Exception exception) {
            try {
                result.put("ok", false);
                result.put("message", "Android network cache refresh failed: " + safeString(exception.getMessage()));
                result.put("details", details);
                return result.toString();
            } catch (Exception ignored) {
                return "{\"ok\":false,\"message\":\"Android network cache refresh failed.\",\"details\":[]}";
            }
        }
    }

    public static boolean isRunning() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid ? state.running : GenyConnectVpnService.isRunning();
    }

    public static boolean queryState() {
        final Context context = context();
        if (context == null) {
            final RuntimeState state = queryLiveRuntimeState();
            return state.valid ? state.running : GenyConnectVpnService.isRunning();
        }

        final RuntimeState state = queryLiveRuntimeState();
        if (state.valid) {
            return state.running;
        }

        final Intent queryIntent = new Intent(context, GenyConnectVpnService.class);
        queryIntent.setAction(GenyConnectVpnService.ACTION_QUERY_STATE);
        try {
            context.startService(queryIntent);
        } catch (Exception ignored) {
        }

        final RuntimeState refreshedState = queryLiveRuntimeState();
        return refreshedState.valid ? refreshedState.running : GenyConnectVpnService.isRunning();
    }

    public static boolean isStartupPending() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid && state.startupPending;
    }

    public static boolean isRuntimeAlive() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid ? state.runtimeAlive : GenyConnectVpnService.runtimeProcessAliveInProcess();
    }

    public static String lastError() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid ? state.lastError : GenyConnectVpnService.lastError();
    }

    public static String runtimeDiagnostics() {
        final String diagnostics = GenyConnectVpnService.lastDiagnosticsInProcess();
        if (!safeString(diagnostics).isEmpty()) {
            return diagnostics;
        }
        return lastError();
    }

    public static long rxBytes() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid ? state.rxBytes : GenyConnectVpnService.rxBytes();
    }

    public static long txBytes() {
        final RuntimeState state = queryLiveRuntimeState();
        return state.valid ? state.txBytes : GenyConnectVpnService.txBytes();
    }

    private static RuntimeState queryLiveRuntimeState() {
        final long nowElapsedMs = SystemClock.elapsedRealtime();
        final RuntimeState cached = sCachedRuntimeState;
        if (cached.valid && (nowElapsedMs - cached.queriedElapsedMs) <= STATE_CACHE_TTL_MS) {
            return cached.copy();
        }
        if (Boolean.TRUE.equals(IN_STATE_QUERY.get())) {
            return queryLiveRuntimeStateDirect();
        }
        if (!STATE_QUERY_IN_FLIGHT.compareAndSet(false, true)) {
            return cachedStateIfFresh(nowElapsedMs);
        }

        final Future<RuntimeState> future = STATE_QUERY_EXECUTOR.submit(() -> {
            IN_STATE_QUERY.set(Boolean.TRUE);
            try {
                final RuntimeState state = queryLiveRuntimeStateDirect();
                if (state.valid) {
                    sCachedRuntimeState = state.copy();
                }
                return state;
            } finally {
                IN_STATE_QUERY.remove();
                STATE_QUERY_IN_FLIGHT.set(false);
            }
        });
        try {
            final RuntimeState state = future.get(STATE_QUERY_TIMEOUT_MS, TimeUnit.MILLISECONDS);
            if (state.valid) {
                sCachedRuntimeState = state.copy();
            }
            return state;
        } catch (TimeoutException exception) {
            future.cancel(true);
            android.util.Log.w(TAG, "Timed out while querying live VPN state; using bounded fallback.");
            return cachedStateIfFresh(nowElapsedMs);
        } catch (Exception exception) {
            future.cancel(true);
            android.util.Log.w(TAG, "Failed to query live VPN state: " + exception.getMessage());
            STATE_QUERY_IN_FLIGHT.set(false);
            return cachedStateIfFresh(nowElapsedMs);
        }
    }

    private static RuntimeState cachedStateIfFresh(long nowElapsedMs) {
        final RuntimeState cached = sCachedRuntimeState;
        if (cached.valid && (nowElapsedMs - cached.queriedElapsedMs) <= STATE_STALE_FALLBACK_MS) {
            return cached.copy();
        }
        return new RuntimeState();
    }

    private static RuntimeState queryLiveRuntimeStateDirect() {
        final RuntimeState state = new RuntimeState();
        final Context appContext = context();
        if (appContext == null) {
            return state;
        }

        Cursor cursor = null;
        try {
            final Uri uri = Uri.parse("content://" + appContext.getPackageName()
                + VPN_STATE_AUTHORITY_SUFFIX + "/" + VPN_STATE_PATH);
            cursor = appContext.getContentResolver().query(uri, null, null, null, null);
            if (cursor == null || !cursor.moveToFirst()) {
                return state;
            }

            state.running = cursor.getInt(cursor.getColumnIndexOrThrow(GenyConnectVpnStateProvider.COL_RUNNING)) != 0;
            state.rxBytes = Math.max(0L, cursor.getLong(cursor.getColumnIndexOrThrow(GenyConnectVpnStateProvider.COL_RX_BYTES)));
            state.txBytes = Math.max(0L, cursor.getLong(cursor.getColumnIndexOrThrow(GenyConnectVpnStateProvider.COL_TX_BYTES)));
            state.lastError = safeString(cursor.getString(cursor.getColumnIndexOrThrow(GenyConnectVpnStateProvider.COL_LAST_ERROR)));
            final int startQueuedColumn = cursor.getColumnIndex(GenyConnectVpnStateProvider.COL_START_QUEUED);
            if (startQueuedColumn >= 0) {
                state.startupPending = cursor.getInt(startQueuedColumn) != 0;
            }
            final int runtimeAliveColumn = cursor.getColumnIndex(GenyConnectVpnStateProvider.COL_RUNTIME_ALIVE);
            if (runtimeAliveColumn >= 0) {
                state.runtimeAlive = cursor.getInt(runtimeAliveColumn) != 0;
            }
            state.queriedElapsedMs = SystemClock.elapsedRealtime();
            state.valid = true;
        } catch (Exception ignored) {
            state.valid = false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
        return state;
    }

    public static boolean moveTaskToBack() {
        final Activity currentActivity = activity();
        if (currentActivity == null) {
            return false;
        }
        try {
            currentActivity.runOnUiThread(() -> {
                try {
                    currentActivity.moveTaskToBack(true);
                } catch (Exception ignored) {
                }
            });
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static int batteryLevel() {
        final Context context = context();
        if (context == null) {
            return -1;
        }
        try {
            final Intent battery = context.registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            if (battery == null) {
                return -1;
            }
            final int level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
            final int scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
            if (level < 0 || scale <= 0) {
                return -1;
            }
            return Math.max(0, Math.min(100, Math.round((level * 100.0f) / scale)));
        } catch (Exception ignored) {
            return -1;
        }
    }

    public static boolean isCharging() {
        final Context context = context();
        if (context == null) {
            return false;
        }
        try {
            final Intent battery = context.registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            if (battery == null) {
                return false;
            }
            final int status = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
            final int plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0);
            return status == BatteryManager.BATTERY_STATUS_CHARGING
                || status == BatteryManager.BATTERY_STATUS_FULL
                || plugged != 0;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean isBatterySaverEnabled() {
        final Context context = context();
        if (context == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false;
        }
        try {
            final PowerManager powerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            return powerManager != null && powerManager.isPowerSaveMode();
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean isScreenOn() {
        final Context context = context();
        if (context == null) {
            return true;
        }
        try {
            final PowerManager powerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            if (powerManager == null) {
                return true;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
                return powerManager.isInteractive();
            }
            return powerManager.isScreenOn();
        } catch (Exception ignored) {
            return true;
        }
    }

    public static String networkType() {
        final Context context = context();
        if (context == null) {
            return "unknown";
        }
        try {
            final ConnectivityManager manager =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (manager == null) {
                return "unknown";
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                final Network network = manager.getActiveNetwork();
                final NetworkCapabilities capabilities = network == null ? null : manager.getNetworkCapabilities(network);
                if (capabilities == null) {
                    return "unknown";
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                    return "wifi";
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                    return "cellular";
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                    return "ethernet";
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH)) {
                    return "bluetooth";
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    return "vpn";
                }
                return "unknown";
            }

            final NetworkInfo info = manager.getActiveNetworkInfo();
            if (info == null || !info.isConnected()) {
                return "unknown";
            }
            switch (info.getType()) {
            case ConnectivityManager.TYPE_WIFI:
                return "wifi";
            case ConnectivityManager.TYPE_MOBILE:
                return "cellular";
            case ConnectivityManager.TYPE_ETHERNET:
                return "ethernet";
            case ConnectivityManager.TYPE_BLUETOOTH:
                return "bluetooth";
            case ConnectivityManager.TYPE_VPN:
                return "vpn";
            default:
                return "unknown";
            }
        } catch (Exception ignored) {
            return "unknown";
        }
    }

    public static boolean openUrlWithChooser(String rawUrl, String chooserTitle) {
        final String targetUrl = safeString(rawUrl);
        if (targetUrl.isEmpty()) {
            return false;
        }

        final Uri targetUri;
        try {
            targetUri = Uri.parse(targetUrl);
        } catch (Exception ignored) {
            return false;
        }
        if (targetUri == null) {
            return false;
        }

        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return false;
        }
        ensureStandardSystemUi(currentActivity);

        final Intent viewIntent = new Intent(Intent.ACTION_VIEW, targetUri);
        viewIntent.addCategory(Intent.CATEGORY_BROWSABLE);
        if (currentActivity == null) {
            viewIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        final String chooserLabel = safeString(chooserTitle).isEmpty()
            ? "Open with"
            : safeString(chooserTitle);
        final Intent chooserIntent = Intent.createChooser(viewIntent, chooserLabel);
        if (currentActivity == null) {
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        try {
            if (currentActivity != null) {
                currentActivity.startActivity(chooserIntent);
            } else {
                launchContext.startActivity(chooserIntent);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean openSystemProxySettings() {
        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return false;
        }
        ensureStandardSystemUi(currentActivity);

        final String[] actions = new String[] {
            Settings.ACTION_WIFI_IP_SETTINGS,
            Settings.ACTION_WIFI_SETTINGS,
            Settings.ACTION_SETTINGS
        };

        for (String action : actions) {
            try {
                final Intent intent = new Intent(action);
                if (currentActivity == null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                }
                if (currentActivity != null) {
                    currentActivity.startActivity(intent);
                } else {
                    launchContext.startActivity(intent);
                }
                return true;
            } catch (Exception ignored) {
            }
        }
        return false;
    }

    public static boolean isIgnoringBatteryOptimizations() {
        final Context appContext = context();
        if (appContext == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }
        try {
            final PowerManager powerManager = (PowerManager) appContext.getSystemService(Context.POWER_SERVICE);
            return powerManager == null || powerManager.isIgnoringBatteryOptimizations(appContext.getPackageName());
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean openBatteryOptimizationSettings() {
        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return false;
        }
        ensureStandardSystemUi(currentActivity);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !isIgnoringBatteryOptimizations()) {
            final Intent requestIntent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            requestIntent.setData(Uri.parse("package:" + launchContext.getPackageName()));
            if (launchSettingsIntent(currentActivity, launchContext, requestIntent)) {
                return true;
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            final Intent listIntent = new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
            if (launchSettingsIntent(currentActivity, launchContext, listIntent)) {
                return true;
            }
        }

        final Intent detailsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        detailsIntent.setData(Uri.parse("package:" + launchContext.getPackageName()));
        if (launchSettingsIntent(currentActivity, launchContext, detailsIntent)) {
            return true;
        }

        return launchSettingsIntent(currentActivity, launchContext, new Intent(Settings.ACTION_SETTINGS));
    }

    private static boolean launchSettingsIntent(Activity currentActivity, Context launchContext, Intent intent) {
        try {
            if (currentActivity == null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            }
            if (currentActivity != null) {
                currentActivity.startActivity(intent);
            } else {
                launchContext.startActivity(intent);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean shareText(String subject, String text) {
        final String body = safeString(text);
        if (body.isEmpty()) {
            return false;
        }

        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return false;
        }
        ensureStandardSystemUi(currentActivity);

        final Intent shareIntent = new Intent(Intent.ACTION_SEND);
        shareIntent.setType("text/plain");
        final String normalizedSubject = safeString(subject);
        if (!normalizedSubject.isEmpty()) {
            shareIntent.putExtra(Intent.EXTRA_SUBJECT, normalizedSubject);
        }
        shareIntent.putExtra(Intent.EXTRA_TEXT, body);

        final Intent chooserIntent = Intent.createChooser(shareIntent, "Share GenyConnect");
        if (currentActivity == null) {
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        try {
            if (currentActivity != null) {
                currentActivity.startActivity(chooserIntent);
            } else {
                launchContext.startActivity(chooserIntent);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean openUrlInPackage(String rawUrl, String packageName) {
        final String targetUrl = safeString(rawUrl);
        final String targetPackage = safeString(packageName);
        if (targetUrl.isEmpty() || targetPackage.isEmpty()) {
            return false;
        }

        final Uri targetUri;
        try {
            targetUri = Uri.parse(targetUrl);
        } catch (Exception ignored) {
            return false;
        }
        if (targetUri == null) {
            return false;
        }

        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return false;
        }
        ensureStandardSystemUi(currentActivity);

        final Intent intent = new Intent(Intent.ACTION_VIEW, targetUri);
        intent.addCategory(Intent.CATEGORY_BROWSABLE);
        intent.setPackage(targetPackage);
        if (currentActivity == null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        try {
            if (currentActivity != null) {
                currentActivity.startActivity(intent);
            } else {
                launchContext.startActivity(intent);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    public static boolean isPackageInstalled(String packageName) {
        final String targetPackage = safeString(packageName);
        if (targetPackage.isEmpty()) {
            return false;
        }
        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context sourceContext = currentActivity != null ? currentActivity : appContext;
        if (sourceContext == null) {
            return false;
        }
        try {
            final PackageManager pm = sourceContext.getPackageManager();
            if (pm == null) {
                return false;
            }
            return isPackageInstalled(pm, targetPackage);
        } catch (Exception ignored) {
            return false;
        }
    }

    public static String discoverWalletTargets(String transferUrl, String swapUrl) {
        final JSONArray targets = new JSONArray();
        try {
            final JSONObject chooserTarget = new JSONObject();
            chooserTarget.put("id", "system");
            chooserTarget.put("label", "Any Compatible Wallet");
            chooserTarget.put("mode", "chooser");
            chooserTarget.put("packageName", "");
            targets.put(chooserTarget);
        } catch (Exception ignored) {
        }

        final Activity currentActivity = activity();
        final Context appContext = context();
        final Context sourceContext = currentActivity != null ? currentActivity : appContext;
        if (sourceContext == null) {
            return targets.toString();
        }

        final PackageManager pm = sourceContext.getPackageManager();
        if (pm == null) {
            return targets.toString();
        }

        final Set<String> discoveredPackages = new HashSet<>();
        final String transfer = safeString(transferUrl);
        if (!transfer.isEmpty()) {
            try {
                final Intent transferIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(transfer));
                transferIntent.addCategory(Intent.CATEGORY_BROWSABLE);
                final List<ResolveInfo> handlers = queryIntentHandlers(pm, transferIntent);
                for (ResolveInfo resolveInfo : handlers) {
                    if (resolveInfo == null || resolveInfo.activityInfo == null) {
                        continue;
                    }
                    final String packageName = safeString(resolveInfo.activityInfo.packageName);
                    if (packageName.isEmpty() || discoveredPackages.contains(packageName)) {
                        continue;
                    }
                    discoveredPackages.add(packageName);

                    String label = "";
                    try {
                        final CharSequence seq = resolveInfo.loadLabel(pm);
                        label = seq == null ? "" : seq.toString().trim();
                    } catch (Exception ignored) {
                    }
                    if (label.isEmpty()) {
                        label = packageName;
                    }

                    final JSONObject row = new JSONObject();
                    row.put("id", packageName);
                    row.put("label", label);
                    row.put("mode", "transfer");
                    row.put("packageName", packageName);
                    targets.put(row);
                }
            } catch (Exception ignored) {
            }
        }

        maybeAppendKnownWallet(targets, discoveredPackages, pm, "com.uniswap.mobile", "Uniswap Wallet", "swap");
        maybeAppendKnownWallet(targets, discoveredPackages, pm, "org.toshi", "Base Wallet", "transfer");
        maybeAppendKnownWallet(targets, discoveredPackages, pm, "io.metamask", "MetaMask", "transfer");
        maybeAppendKnownWallet(targets, discoveredPackages, pm, "io.debank.rabbymobile", "Rabby Wallet", "transfer");

        return targets.toString();
    }

    public static String fetchSubscriptionText(String rawUrl, int timeoutMs) {
        final String targetUrl = safeString(rawUrl);
        if (targetUrl.isEmpty()) {
            return subscriptionFetchResult(false, "", "Subscription URL is empty.", -1);
        }

        final int safeTimeoutMs = Math.max(2000, Math.min(45000, timeoutMs));
        HttpURLConnection connection = null;
        try {
            final URL url = new URL(targetUrl);
            final java.net.URLConnection rawConnection = url.openConnection();
            if (!(rawConnection instanceof HttpURLConnection)) {
                return subscriptionFetchResult(false, "", "Unsupported subscription protocol.", -1);
            }
            connection = (HttpURLConnection) rawConnection;
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(safeTimeoutMs);
            connection.setReadTimeout(safeTimeoutMs);
            connection.setInstanceFollowRedirects(true);
            connection.setUseCaches(false);
            connection.setRequestProperty("User-Agent", "GenyConnect-Subscription/1.0");
            connection.setRequestProperty("Accept", "*/*");
            connection.setRequestProperty("Cache-Control", "no-cache");
            connection.setRequestProperty("Pragma", "no-cache");

            final int statusCode = connection.getResponseCode();
            final boolean success = statusCode >= 200 && statusCode < 300;
            final InputStream stream = success ? connection.getInputStream() : connection.getErrorStream();
            final String payload = readStreamText(stream);
            if (success) {
                return subscriptionFetchResult(true, payload, "", statusCode);
            }

            String message = "HTTP " + statusCode;
            final String responseMessage = safeString(connection.getResponseMessage());
            if (!responseMessage.isEmpty()) {
                message = message + " " + responseMessage;
            }
            return subscriptionFetchResult(false, "", message, statusCode);
        } catch (java.net.SocketTimeoutException exception) {
            return subscriptionFetchResult(false, "", "Request timed out.", -1);
        } catch (Exception exception) {
            final String message = safeString(exception.getMessage());
            return subscriptionFetchResult(false, "", message.isEmpty() ? "Connection failed." : message, -1);
        } finally {
            if (connection != null) {
                try {
                    connection.disconnect();
                } catch (Exception ignored) {
                }
            }
        }
    }

    public static String downloadFileToPath(String rawUrl, String rawPath, int timeoutMs) {
        final String targetUrl = safeString(rawUrl);
        final String targetPath = safeString(rawPath);
        if (targetUrl.isEmpty() || targetPath.isEmpty()) {
            return subscriptionFetchResult(false, "", "Download URL or output path is empty.", -1);
        }

        final int safeTimeoutMs = Math.max(5000, Math.min(90000, timeoutMs));
        HttpURLConnection connection = null;
        File targetFile = null;
        try {
            final URL url = new URL(targetUrl);
            final java.net.URLConnection rawConnection = url.openConnection();
            if (!(rawConnection instanceof HttpURLConnection)) {
                return subscriptionFetchResult(false, "", "Unsupported download protocol.", -1);
            }
            connection = (HttpURLConnection) rawConnection;
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(safeTimeoutMs);
            connection.setReadTimeout(safeTimeoutMs);
            connection.setInstanceFollowRedirects(true);
            connection.setUseCaches(false);
            connection.setRequestProperty("User-Agent", "GenyConnect-Updater/1.0");
            connection.setRequestProperty("Accept", "*/*");
            connection.setRequestProperty("Cache-Control", "no-cache");
            connection.setRequestProperty("Pragma", "no-cache");

            final int statusCode = connection.getResponseCode();
            if (statusCode < 200 || statusCode >= 300) {
                String message = "HTTP " + statusCode;
                final String responseMessage = safeString(connection.getResponseMessage());
                if (!responseMessage.isEmpty()) {
                    message = message + " " + responseMessage;
                }
                return subscriptionFetchResult(false, "", message, statusCode);
            }

            targetFile = new File(targetPath);
            final File parent = targetFile.getParentFile();
            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                return subscriptionFetchResult(false, "", "Could not prepare output directory.", -1);
            }

            try (InputStream inputStream = connection.getInputStream();
                 FileOutputStream outputStream = new FileOutputStream(targetFile, false)) {
                final byte[] buffer = new byte[8192];
                int read;
                while ((read = inputStream.read(buffer)) != -1) {
                    if (read <= 0) {
                        continue;
                    }
                    outputStream.write(buffer, 0, read);
                }
                outputStream.flush();
            }

            return subscriptionFetchResult(true, "", "", statusCode);
        } catch (java.net.SocketTimeoutException exception) {
            if (targetFile != null) {
                try {
                    targetFile.delete();
                } catch (Exception ignored) {
                }
            }
            return subscriptionFetchResult(false, "", "Request timed out.", -1);
        } catch (Exception exception) {
            if (targetFile != null) {
                try {
                    targetFile.delete();
                } catch (Exception ignored) {
                }
            }
            final String message = safeString(exception.getMessage());
            return subscriptionFetchResult(false, "", message.isEmpty() ? "Download failed." : message, -1);
        } finally {
            if (connection != null) {
                try {
                    connection.disconnect();
                } catch (Exception ignored) {
                }
            }
        }
    }

    private static List<ResolveInfo> queryIntentHandlers(PackageManager pm, Intent intent) {
        if (pm == null || intent == null) {
            return new ArrayList<>();
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                return pm.queryIntentActivities(intent,
                    PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY));
            }
            return pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
        } catch (Exception ignored) {
            return new ArrayList<>();
        }
    }

    private static boolean isPackageInstalled(PackageManager pm, String packageName) {
        if (pm == null || packageName == null || packageName.trim().isEmpty()) {
            return false;
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0));
            } else {
                pm.getPackageInfo(packageName, 0);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String subscriptionFetchResult(boolean ok, String payload, String error, int statusCode) {
        final JSONObject result = new JSONObject();
        try {
            result.put("ok", ok);
            result.put("payload", safeString(payload));
            result.put("error", safeString(error));
            if (statusCode >= 0) {
                result.put("statusCode", statusCode);
            }
        } catch (Exception ignored) {
        }
        return result.toString();
    }

    private static String readStreamText(InputStream stream) {
        if (stream == null) {
            return "";
        }
        final StringBuilder content = new StringBuilder(8192);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            final char[] buffer = new char[2048];
            int read;
            while ((read = reader.read(buffer)) != -1) {
                content.append(buffer, 0, read);
                if (content.length() > (4 * 1024 * 1024)) {
                    break;
                }
            }
        } catch (Exception ignored) {
        }
        return content.toString();
    }

    private static void maybeAppendKnownWallet(JSONArray targets,
                                               Set<String> discoveredPackages,
                                               PackageManager pm,
                                               String packageName,
                                               String label,
                                               String mode) {
        if (targets == null || discoveredPackages == null || pm == null) {
            return;
        }
        final String pkg = safeString(packageName);
        if (pkg.isEmpty() || discoveredPackages.contains(pkg) || !isPackageInstalled(pm, pkg)) {
            return;
        }
        try {
            final JSONObject row = new JSONObject();
            row.put("id", pkg);
            row.put("label", safeString(label).isEmpty() ? pkg : label);
            row.put("mode", safeString(mode).isEmpty() ? "transfer" : mode);
            row.put("packageName", pkg);
            targets.put(row);
            discoveredPackages.add(pkg);
        } catch (Exception ignored) {
        }
    }

    public static void syncSystemBars(boolean darkThemeEnabled) {
        final Activity currentActivity = activity();
        if (currentActivity == null) {
            return;
        }

        currentActivity.runOnUiThread(() -> {
            try {
                final Window window = currentActivity.getWindow();
                if (window == null) {
                    return;
                }

                // Keep Android in standard non-immersive app chrome mode after choosers/intents.
                window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
                WindowCompat.setDecorFitsSystemWindows(window, true);

                final int barColor = darkThemeEnabled ? 0xFF091A33 : 0xFFFFFFFF;

                window.setStatusBarColor(barColor);
                window.setNavigationBarColor(barColor);
                applySystemBarAppearance(window, darkThemeEnabled);
            } catch (Exception ignored) {
            }
        });
    }

    public static String installDownloadedApk(String apkPath) {
        final String path = safeString(apkPath);
        if (path.isEmpty()) {
            return "Downloaded APK path is empty.";
        }

        final Context appContext = context();
        final Activity currentActivity = activity();
        final Context launchContext = currentActivity != null ? currentActivity : appContext;
        if (launchContext == null) {
            return "Android runtime context is unavailable.";
        }
        ensureStandardSystemUi(currentActivity);

        final File apkFile = new File(path);
        if (!apkFile.exists()) {
            return "Downloaded APK was not found.";
        }

        final String authority = launchContext.getPackageName() + ".qtprovider";
        final Uri apkUri;
        try {
            apkUri = FileProvider.getUriForFile(launchContext, authority, apkFile);
        } catch (Exception exception) {
            return "Failed to create install URI for APK: " + exception.getMessage();
        }

        final Intent installIntent = new Intent(Intent.ACTION_VIEW);
        installIntent.setDataAndType(apkUri, "application/vnd.android.package-archive");
        installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        if (currentActivity == null) {
            installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        }

        try {
            if (currentActivity != null) {
                currentActivity.startActivity(installIntent);
            } else {
                launchContext.startActivity(installIntent);
            }
            return "";
        } catch (Exception exception) {
            return "Failed to open Android package installer: " + exception.getMessage();
        }
    }

    private static String safeString(String value) {
        return value == null ? "" : value.trim();
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
}
