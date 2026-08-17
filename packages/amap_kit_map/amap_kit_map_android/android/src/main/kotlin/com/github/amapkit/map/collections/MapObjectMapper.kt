package com.github.amapkit.map.collections

import android.os.Looper
import com.amap.api.maps.AMap

abstract class MapObjectManager<O, C : ObjectCollection<O>>(internal val map: AMap) {
    private val namedCollections = mutableMapOf<String, C>()

    /**
     * object -> collection
     *
     * 用于快速 remove
     */
    protected val objectCollections = mutableMapOf<O, C>()

    init {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "Map object managers must be created on the Android main thread."
        }
        registerMapListeners()
    }
    /**
     * 注册地图监听
     * 必须在主线程执行
     */
    protected abstract fun registerMapListeners()
    /**
     * 创建集合
     */
    abstract fun createCollection(): C


    /**
     * 删除地图对象
     */
    fun newCollection(id: String): C {
        check(id !in namedCollections) {
            "collection id is not unique: $id"
        }
        return createCollection().also { namedCollections[id] = it }
    }

    operator fun get(id: String): C? = namedCollections[id]

    fun remove(obj: O) = objectCollections[obj]?.remove(obj) ?: false

    internal fun registerObject(obj: O, collection: C) {
        objectCollections[obj] = collection
    }

    internal fun unregisterObject(obj: O) {
        objectCollections.remove(obj)
    }
}
