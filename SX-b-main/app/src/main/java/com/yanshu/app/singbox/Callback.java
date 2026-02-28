package com.yanshu.app.singbox;

public interface Callback {
    int K_Disconnected = 0;
    int K_Connecting = 1;
    int K_Connected = 2;

    void connectionStatusDidChange(int status);
    void onPingResponse(int rtt, String uri);
}
