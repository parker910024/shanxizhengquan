package com.yanshu.app.singbox;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

public class VPNManager {
    private int currentStatus = Callback.K_Disconnected;
    private Context applicationContext = null;
    private Callback callback = null;
    private static volatile VPNManager g_instance = null;
    private Handler uiHandler;

    public static VPNManager sharedManager() {
        if (g_instance == null) {
            synchronized (VPNManager.class) {
                if (g_instance == null) {
                    g_instance = new VPNManager();
                    g_instance.uiHandler = new Handler(Looper.getMainLooper());
                }
            }
        }
        return g_instance;
    }

    public void setVPNConectionStatusCallback(Callback callback) {
        this.callback = callback;
    }

    public int getCurrentStatus() {
        return currentStatus;
    }

    private void invokeCallback(int status) {
        currentStatus = status;
        if (callback != null) {
            if (Looper.myLooper() == Looper.getMainLooper()) {
                callback.connectionStatusDidChange(status);
            } else {
                uiHandler.post(() -> callback.connectionStatusDidChange(status));
            }
        }
    }

    public void setApplicationContext(Context context) {
        if (applicationContext != null) return;
        applicationContext = context.getApplicationContext();

        SingBoxProcess.INSTANCE.init(applicationContext);
        SingBoxProcess.INSTANCE.setCallback(new Callback() {
            @Override
            public void connectionStatusDidChange(int status) {
                invokeCallback(status);
            }

            @Override
            public void onPingResponse(int rtt, String uri) {
                if (callback != null) {
                    callback.onPingResponse(rtt, uri);
                }
            }
        });
    }

    public boolean startTunnel(String configJson) {
        if (applicationContext == null) {
            return false;
        }
        if (currentStatus == Callback.K_Connected || currentStatus == Callback.K_Connecting) {
            return true;
        }

        SingBoxProcess.INSTANCE.start(configJson);
        return true;
    }

    public boolean stopTunnel() {
        if (applicationContext == null) return false;

        SingBoxProcess.INSTANCE.stop();
        currentStatus = Callback.K_Disconnected;
        return true;
    }
}
