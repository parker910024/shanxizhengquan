package ex.ss.lib.http

import ex.ss.lib.http.client.ISSHttpClient

object SSHttp {

    private lateinit var httpClient: ISSHttpClient

    internal fun requireHttpClient(): ISSHttpClient {
        return httpClient
    }

    fun initClient(client: ISSHttpClient) = synchronized(this) {
        if (!this::httpClient.isInitialized) {
            this.httpClient = client
        }
    }


}