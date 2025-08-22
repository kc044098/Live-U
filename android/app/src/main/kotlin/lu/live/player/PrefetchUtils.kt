package lu.live.player

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.Cache
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.CacheWriter

/**
 * MP4 首段預取到 SimpleCache（Media3 1.8.0 相容版）
 * 使用 CacheWriter 的建構子：(CacheDataSource, DataSpec, temporaryBuffer, progressListener)
 */

data class PrefetchHandle(val cancel: () -> Unit)

object PrefetchUtils {

    @OptIn(UnstableApi::class)
    private fun upstreamFactory(
        context: Context,
        userAgent: String,
        headers: Map<String, String>?
    ): DataSource.Factory {
        val http = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(8_000)
            .setReadTimeoutMs(8_000)
            .setAllowCrossProtocolRedirects(true)
        headers?.let { http.setDefaultRequestProperties(it) }
        return DefaultDataSource.Factory(context, http)
    }

    @OptIn(UnstableApi::class)
    private fun buildCacheDataSource(
        context: Context,
        userAgent: String,
        headers: Map<String, String>?
    ): CacheDataSource {
        val cache: Cache = ExoCache.get(context)
        val upstream = upstreamFactory(context, userAgent, headers)
        return CacheDataSource.Factory()
            .setCache(cache)
            .setUpstreamDataSourceFactory(upstream)
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
            .createDataSource() as CacheDataSource
    }

    /**
     * 產生穩定的快取 key：
     * 1) 若有自訂 cacheKey 就用它
     * 2) 否則用 DataSpec.key
     * 3) 再否則用去掉 query/fragment 的 URL 當 key
     */
    @OptIn(UnstableApi::class)
    private fun stableCacheKey(spec: DataSpec, cacheKey: String?): String {
        if (!cacheKey.isNullOrEmpty()) return cacheKey
        spec.key?.let { if (it.isNotEmpty()) return it }
        val s = spec.uri.toString()
        return s.substringBefore('#').substringBefore('?')
    }

    /**
     * 將 MP4 的 [0, bytes) 區段預先寫入 SimpleCache。
     * 回傳 PrefetchHandle 以便取消任務。
     */
    @OptIn(UnstableApi::class)
    fun prefetchMp4Head(
        context: Context,
        url: String,
        bytes: Long = 3L * 1024 * 1024,
        cacheKey: String? = null,
        headers: Map<String, String>? = null,
        onProgress: ((cachedBytes: Long, totalBytes: Long, newlyCachedBytes: Long) -> Unit)? = null
    ): PrefetchHandle {
        // 1) 建立 DataSpec，並設定穩定的 key 以提升命中率
        val baseSpec = DataSpec.Builder()
            .setUri(url)
            .setPosition(0)
            .setLength(bytes)
            .build()
        val stableKey = stableCacheKey(baseSpec, cacheKey)
        val dataSpec = baseSpec.buildUpon().setKey(stableKey).build()

        // 2) 進度監聽（可選）
        val listener = CacheWriter.ProgressListener { requestLength, bytesCached, newlyCachedBytes ->
            onProgress?.invoke(bytesCached, requestLength, newlyCachedBytes)
        }

        // 3) 用 CacheDataSource 建立 CacheWriter（1.8.0 為 4 參數建構子）
        val cacheDs: CacheDataSource = buildCacheDataSource(context, "djs-live/1.0", headers)
        val writer = CacheWriter(
            cacheDs,
            dataSpec,
            /* temporaryBuffer = */ null,
            /* progressListener = */ listener
        )

        val thread = Thread {
            try { writer.cache() } catch (_: Throwable) {}
        }
        thread.start()

        return PrefetchHandle(
            cancel = {
                try { writer.cancel() } catch (_: Throwable) {}
                try { thread.interrupt() } catch (_: Throwable) {}
            }
        )
    }
}
