package com.github.amapkit.map.overlays.tile

import android.os.Handler
import android.os.Looper
import com.amap.api.maps.model.Tile
import com.amap.api.maps.model.TileProvider
import com.github.amapkit.map.MapsCallbackApi
import com.github.amapkit.map.PlatformTile
import com.github.amapkit.map.PlatformTileCoordinate
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

/** Bridges AMap's synchronous tile worker to the asynchronous Dart provider. */
class TileProviderController(
    private val flutterApi: MapsCallbackApi,
    private val tileOverlayId: String,
    private val tileSize: Int
) : TileProvider {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var disposed = false
    private val pendingRequests = ConcurrentHashMap.newKeySet<CountDownLatch>()

    override fun getTile(x: Int, y: Int, zoom: Int): Tile {
        if (disposed) return TileProvider.NO_TILE
        val latch = CountDownLatch(1)
        pendingRequests.add(latch)
        var result: PlatformTile? = null
        mainHandler.post {
            if (disposed) {
                latch.countDown()
                return@post
            }
            flutterApi.getTileOverlayTile(
                tileOverlayId,
                PlatformTileCoordinate(x.toLong(), y.toLong()),
                zoom.toLong()
            ) { response ->
                result = response.getOrNull()
                latch.countDown()
            }
        }
        return try {
            if (!latch.await(TILE_TIMEOUT_SECONDS, TimeUnit.SECONDS) || disposed) {
                TileProvider.NO_TILE
            } else {
                result.toNativeTile()
            }
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            TileProvider.NO_TILE
        } finally {
            pendingRequests.remove(latch)
        }
    }

    override fun getTileWidth(): Int = tileSize

    override fun getTileHeight(): Int = tileSize

    fun dispose() {
        disposed = true
        pendingRequests.forEach(CountDownLatch::countDown)
        pendingRequests.clear()
    }

    private fun PlatformTile?.toNativeTile(): Tile {
        val tile = this ?: return TileProvider.NO_TILE
        val bytes = tile.data ?: return TileProvider.NO_TILE
        if (tile.width <= 0 || tile.height <= 0) return TileProvider.NO_TILE
        return Tile(tile.width.toInt(), tile.height.toInt(), bytes)
    }

    private companion object {
        const val TILE_TIMEOUT_SECONDS = 15L
    }
}
