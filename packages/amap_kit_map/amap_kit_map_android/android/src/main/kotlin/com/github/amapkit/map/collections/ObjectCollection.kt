package com.github.amapkit.map.collections

abstract class ObjectCollection<O>(private val onRemove: (O) -> Unit) {
    private val objects = linkedSetOf<O>()

    val values: Collection<O>
        get() = objects.toList()

    protected fun addObject(obj: O) {
        objects += obj
    }

    fun remove(obj: O): Boolean {
        if (!objects.remove(obj)) return false
        onRemove(obj)
        return true
    }

    fun clear() {
        objects.forEach(onRemove)
        objects.clear()
    }

}
