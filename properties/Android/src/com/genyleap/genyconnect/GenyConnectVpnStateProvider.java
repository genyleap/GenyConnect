package com.genyleap.genyconnect;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;

public final class GenyConnectVpnStateProvider extends ContentProvider {
    static final String PATH_STATE = "state";
    static final String COL_RUNNING = "running";
    static final String COL_RX_BYTES = "rx_bytes";
    static final String COL_TX_BYTES = "tx_bytes";
    static final String COL_LAST_ERROR = "last_error";
    static final String COL_PID = "pid";
    static final String COL_UPDATED_AT_MS = "updated_at_ms";
    static final String COL_START_QUEUED = "start_queued";
    static final String COL_RUNTIME_ALIVE = "runtime_alive";

    private static final String[] COLUMNS = new String[] {
        COL_RUNNING,
        COL_RX_BYTES,
        COL_TX_BYTES,
        COL_LAST_ERROR,
        COL_PID,
        COL_UPDATED_AT_MS,
        COL_START_QUEUED,
        COL_RUNTIME_ALIVE
    };

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor query(Uri uri,
                        String[] projection,
                        String selection,
                        String[] selectionArgs,
                        String sortOrder) {
        if (uri == null || !PATH_STATE.equals(uri.getLastPathSegment())) {
            return null;
        }

        final MatrixCursor cursor = new MatrixCursor(COLUMNS, 1);
        final boolean running = GenyConnectVpnService.sessionRunningInProcess();
        cursor.addRow(new Object[] {
            running ? 1 : 0,
            running ? GenyConnectVpnService.rxBytesInProcess() : 0L,
            running ? GenyConnectVpnService.txBytesInProcess() : 0L,
            GenyConnectVpnService.lastErrorInProcess(),
            android.os.Process.myPid(),
            System.currentTimeMillis(),
            GenyConnectVpnService.startupPendingInProcess() ? 1 : 0,
            GenyConnectVpnService.runtimeProcessAliveInProcess() ? 1 : 0
        });
        return cursor;
    }

    @Override
    public String getType(Uri uri) {
        return "vnd.android.cursor.item/vnd.genyconnect.vpnstate";
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        return null;
    }

    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        return 0;
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
        return 0;
    }
}
