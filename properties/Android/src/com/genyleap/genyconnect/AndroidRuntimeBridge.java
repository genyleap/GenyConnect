package com.genyleap.genyconnect;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.VpnService;
import android.os.BatteryManager;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;
import android.content.SharedPreferences;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import androidx.core.content.FileProvider;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.json.JSONArray;
import org.json.JSONObject;

public final class AndroidRuntimeBridge {
    private static final String PERMISSION_PROMPT_LAUNCHED =
        "Android VPN permission is required. Grant it and tap Connect again.";
    private static final String PREFS_NAME = "genyconnect_vpn";
    private static final String PREF_PROMPT_AT_MS = "prompt_at_ms";
    private static final String PREF_PROMPT_COUNT = "prompt_count";

    private AndroidRuntimeBridge() {
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
        startIntent.setAction(GenyConnectVpnService.ACTION_START);
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
        stopIntent.setAction(GenyConnectVpnService.ACTION_STOP);
        try {
            context.startService(stopIntent);
        } catch (Exception exception) {
            return "Failed to stop Android VPN service: " + exception.getMessage();
        }

        return "";
    }

    public static boolean isRunning() {
        return GenyConnectVpnService.isRunning();
    }

    public static String lastError() {
        return GenyConnectVpnService.lastError();
    }

    public static long rxBytes() {
        return GenyConnectVpnService.rxBytes();
    }

    public static long txBytes() {
        return GenyConnectVpnService.txBytes();
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

                final int barColor = darkThemeEnabled ? 0xFF061730 : 0xFFDDE3EA;
                final boolean lightBarIcons = !darkThemeEnabled;

                window.setStatusBarColor(barColor);
                window.setNavigationBarColor(barColor);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    final WindowInsetsController controller = window.getInsetsController();
                    if (controller != null) {
                        final int appearanceMask =
                            WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                                | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
                        final int appearance = lightBarIcons ? appearanceMask : 0;
                        controller.setSystemBarsAppearance(appearance, appearanceMask);
                    }
                    return;
                }

                final View decorView = window.getDecorView();
                if (decorView == null) {
                    return;
                }
                int visibility = decorView.getSystemUiVisibility();
                if (lightBarIcons) {
                    visibility |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        visibility |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                    }
                } else {
                    visibility &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        visibility &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                    }
                }
                decorView.setSystemUiVisibility(visibility);
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
