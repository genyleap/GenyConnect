package com.genyleap.genyconnect;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import android.content.Context;
import android.content.SharedPreferences;

import java.io.File;
import java.io.FileWriter;
import java.util.concurrent.atomic.AtomicBoolean;

import org.qtproject.qt.android.bindings.QtActivity;

public class GenyConnectActivity extends QtActivity {
    private static final String TAG = "GenyConnectActivity";
    private static final String PREFS_NAME = "genyconnect_vpn_runtime";
    private static final String PREF_UI_PROCESS_PID = "ui_process_pid";
    private static final String PREF_UI_PROCESS_UPDATED_AT_MS = "ui_process_updated_at_ms";
    private static final String UI_PROCESS_STATE_FILE = "ui_process_state.txt";
    private static final int REQUEST_POST_NOTIFICATIONS = 43172;
    private static final long UI_PROCESS_EXIT_DELAY_MS = 150L;
    private static final long UI_WATCHDOG_PULSE_MS = 1000L;
    private static final long UI_WATCHDOG_CHECK_MS = 2000L;
    private static final long UI_WATCHDOG_TIMEOUT_MS = 7000L;
    private static final AtomicBoolean sWatchdogStarted = new AtomicBoolean(false);
    private static volatile long sLastMainThreadPulseElapsedMs = 0L;
    private boolean mDestroyExitScheduled = false;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        recordUiProcess();
        startUiWatchdog();
        Log.i(TAG, "onCreate pid=" + android.os.Process.myPid());
        super.onCreate(savedInstanceState);
        ensureNotificationPermission();
    }

    @Override
    protected void onResume() {
        recordUiProcess();
        Log.i(TAG, "onResume pid=" + android.os.Process.myPid());
        super.onResume();
    }

    @Override
    protected void onPause() {
        Log.i(TAG, "onPause pid=" + android.os.Process.myPid());
        super.onPause();
    }

    @Override
    protected void onStop() {
        Log.i(TAG, "onStop pid=" + android.os.Process.myPid());
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        final boolean changingConfigurations = isChangingConfigurations();
        final boolean finishing = isFinishing();
        Log.i(TAG, "onDestroy pid=" + android.os.Process.myPid()
            + " finishing=" + finishing
            + " changingConfigurations=" + changingConfigurations);
        super.onDestroy();

        if (!changingConfigurations) {
            scheduleUiProcessExit();
        }
    }

    private void scheduleUiProcessExit() {
        if (mDestroyExitScheduled) {
            return;
        }
        mDestroyExitScheduled = true;
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Log.i(TAG, "Exiting Android UI process after Activity destroy; VPN service remains in :vpn.");
            android.os.Process.killProcess(android.os.Process.myPid());
            System.exit(0);
        }, UI_PROCESS_EXIT_DELAY_MS);
    }

    private void ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return;
        }
        try {
            requestPermissions(new String[] { Manifest.permission.POST_NOTIFICATIONS }, REQUEST_POST_NOTIFICATIONS);
        } catch (Exception exception) {
            Log.w(TAG, "Failed to request notification permission: " + exception.getMessage());
        }
    }

    private void recordUiProcess() {
        final int pid = android.os.Process.myPid();
        final long updatedAtMs = System.currentTimeMillis();
        try {
            final SharedPreferences preferences =
                getApplicationContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            preferences.edit()
                .putInt(PREF_UI_PROCESS_PID, pid)
                .putLong(PREF_UI_PROCESS_UPDATED_AT_MS, updatedAtMs)
                .commit();
        } catch (Exception exception) {
            Log.w(TAG, "Failed to record UI process pid: " + exception.getMessage());
        }

        try {
            final File stateDir = getApplicationContext().getNoBackupFilesDir();
            final File stateFile = new File(stateDir, UI_PROCESS_STATE_FILE);
            final File tempFile = new File(stateDir, UI_PROCESS_STATE_FILE + ".tmp");
            try (FileWriter writer = new FileWriter(tempFile, false)) {
                writer.write(Integer.toString(pid));
                writer.write('\n');
                writer.write(Long.toString(updatedAtMs));
                writer.write('\n');
            }
            if (!tempFile.renameTo(stateFile)) {
                Log.w(TAG, "Failed to atomically update UI process state file.");
            }
        } catch (Exception exception) {
            Log.w(TAG, "Failed to write UI process state file: " + exception.getMessage());
        }
    }

    private static void startUiWatchdog() {
        if (!sWatchdogStarted.compareAndSet(false, true)) {
            return;
        }

        final Handler mainHandler = new Handler(Looper.getMainLooper());
        final Runnable pulse = new Runnable() {
            @Override
            public void run() {
                sLastMainThreadPulseElapsedMs = SystemClock.elapsedRealtime();
                mainHandler.postDelayed(this, UI_WATCHDOG_PULSE_MS);
            }
        };
        mainHandler.post(pulse);

        final Thread watchdogThread = new Thread(() -> {
            while (true) {
                try {
                    Thread.sleep(UI_WATCHDOG_CHECK_MS);
                } catch (InterruptedException ignored) {
                    return;
                }

                final long lastPulse = sLastMainThreadPulseElapsedMs;
                if (lastPulse <= 0L) {
                    continue;
                }

                final long stalledMs = SystemClock.elapsedRealtime() - lastPulse;
                if (stalledMs > UI_WATCHDOG_TIMEOUT_MS) {
                    Log.e(TAG, "Android UI main thread stalled for " + stalledMs
                        + "ms; terminating only UI process so relaunch starts cleanly.");
                    android.os.Process.killProcess(android.os.Process.myPid());
                    System.exit(0);
                    return;
                }
            }
        }, "GenyConnectUiWatchdog");
        watchdogThread.setDaemon(true);
        watchdogThread.start();
    }
}
