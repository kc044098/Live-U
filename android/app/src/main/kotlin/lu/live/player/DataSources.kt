package lu.live.player

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.CacheDataSink
import androidx.media3.datasource.cache.CacheDataSource

object DataSources {

    @OptIn(UnstableApi::class)
    fun cacheFactory(context: Context, userAgent: String, headers: Map<String, String>? = null): DataSource.Factory {
        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(8_000)
            .setReadTimeoutMs(8_000)
            .setAllowCrossProtocolRedirects(true)

        // 如果要共用 OkHttp（可加 TLS/Proxy/Interceptor）
        // val okHttp = OkHttpClient.Builder().build()
        // val httpFactory = OkHttpDataSource.Factory(okHttp).setUserAgent(userAgent)

        headers?.forEach { (k, v) ->
            httpFactory.setDefaultRequestProperties(mapOf(k to v))
        }

        val upstream: DataSource.Factory = DefaultDataSource.Factory(context, httpFactory)
        val cache = ExoCache.get(context)

        return CacheDataSource.Factory()
            .setCache(cache)
            .setUpstreamDataSourceFactory(upstream)
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
            .setCacheWriteDataSinkFactory(
                CacheDataSink.Factory().setCache(ExoCache.get(context))
            )
    }
}
