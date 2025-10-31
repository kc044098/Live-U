package lu.live.player

import android.content.Context
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.database.StandaloneDatabaseProvider
import java.io.File

@UnstableApi
object ExoCache {
    @Volatile private var cache: SimpleCache? = null

    fun get(context: Context): SimpleCache {
        return cache ?: synchronized(this) {
            cache ?: run {
                val evictor = LeastRecentlyUsedCacheEvictor(1L * 1024 * 1024 * 1024) // 1GB
                val db = StandaloneDatabaseProvider(context)
                val dir = File(context.cacheDir, "exo_cache")
                SimpleCache(dir, evictor, db).also { cache = it }
            }
        }
    }
}
