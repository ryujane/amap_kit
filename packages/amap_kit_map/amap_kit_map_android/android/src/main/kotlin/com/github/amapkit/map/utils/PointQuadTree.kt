package com.github.amapkit.map.utils

class PointQuadTree<T : PointQuadTree.Item> private constructor(
    private val bounds: Bounds,
    private val depth: Int
) {
    interface Item {
        val point: Point
    }

    private val items = linkedSetOf<T>()
    private var children: List<PointQuadTree<T>>? = null

    constructor(bounds: Bounds) : this(bounds, 0)

    constructor(minX: Double, maxX: Double, minY: Double, maxY: Double) :
        this(Bounds(minX, maxX, minY, maxY))

    fun add(item: T) {
        item.point.takeIf { bounds.contains(it) }?.let { point ->
            insert(point.x, point.y, item)
        }
    }

    fun remove(item: T): Boolean =
        item.point.takeIf { bounds.contains(it) }
            ?.let { point -> remove(point.x, point.y, item) }
            ?: false

    fun clear() {
        children = null
        items.clear()
    }

    fun search(searchBounds: Bounds): Collection<T> = buildList {
        search(searchBounds, this)
    }

    private fun insert(x: Double, y: Double, item: T) {
        children?.let {
            childFor(x, y, it).insert(x, y, item)
            return
        }

        items += item
        if (items.size > MAX_ELEMENTS && depth < MAX_DEPTH) split()
    }

    private fun split() {
        children = listOf(
            child(bounds.minX, bounds.midX, bounds.minY, bounds.midY),
            child(bounds.midX, bounds.maxX, bounds.minY, bounds.midY),
            child(bounds.minX, bounds.midX, bounds.midY, bounds.maxY),
            child(bounds.midX, bounds.maxX, bounds.midY, bounds.maxY)
        )

        val itemsToReinsert = items.toList()
        items.clear()
        itemsToReinsert.forEach { item ->
            insert(item.point.x, item.point.y, item)
        }
    }

    private fun child(minX: Double, maxX: Double, minY: Double, maxY: Double) =
        PointQuadTree<T>(Bounds(minX, maxX, minY, maxY), depth + 1)

    private fun childFor(
        x: Double,
        y: Double,
        childNodes: List<PointQuadTree<T>>
    ): PointQuadTree<T> {
        val index = when {
            y < bounds.midY && x < bounds.midX -> TOP_LEFT
            y < bounds.midY -> TOP_RIGHT
            x < bounds.midX -> BOTTOM_LEFT
            else -> BOTTOM_RIGHT
        }
        return childNodes[index]
    }

    private fun remove(x: Double, y: Double, item: T): Boolean =
        children?.let { childFor(x, y, it).remove(x, y, item) }
            ?: items.remove(item)

    private fun search(searchBounds: Bounds, results: MutableCollection<T>) {
        if (!bounds.intersects(searchBounds)) return

        children?.let { childNodes ->
            childNodes.forEach { it.search(searchBounds, results) }
            return
        }

        if (searchBounds.contains(bounds)) {
            results += items
        } else {
            items.filterTo(results) { searchBounds.contains(it.point) }
        }
    }

    private companion object {
        const val TOP_LEFT = 0
        const val TOP_RIGHT = 1
        const val BOTTOM_LEFT = 2
        const val BOTTOM_RIGHT = 3
        const val MAX_ELEMENTS = 50
        const val MAX_DEPTH = 40
    }
}
