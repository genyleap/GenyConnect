package com.genyleap.genyconnect;

import android.os.Process;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

public class GenyConnectActivity extends QtActivity {
    private static final String TAG = "GenyConnectActivity";

    @Override
    protected void onDestroy() {
        if (isFinishing()) {
            Log.i(TAG, "Finishing Android task; terminating UI process and leaving VPN service process alive.");
            Process.killProcess(Process.myPid());
            return;
        }
        super.onDestroy();
    }
}
