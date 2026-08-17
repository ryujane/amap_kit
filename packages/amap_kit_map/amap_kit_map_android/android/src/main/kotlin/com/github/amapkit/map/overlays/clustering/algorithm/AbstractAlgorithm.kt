package com.github.amapkit.map.overlays.clustering.algorithm

import com.github.amapkit.map.overlays.clustering.ClusterItem
import java.util.concurrent.locks.ReadWriteLock
import java.util.concurrent.locks.ReentrantReadWriteLock

abstract class AbstractAlgorithm<T : ClusterItem> : Algorithm<T> {
    private val lock: ReadWriteLock = ReentrantReadWriteLock()

    override fun lock() {
        lock.writeLock().lock()
    }

    override fun unlock() {
        lock.writeLock().unlock()
    }
}
