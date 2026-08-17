package com.github.amapkit.map.overlays.circle

import com.amap.api.maps.AMap
import com.amap.api.maps.model.CircleOptions
import com.github.amapkit.map.Convert
import com.github.amapkit.map.PlatformCircle

/** Maintains every circle belonging to one map instance. */
class CirclesController(private val map: AMap) {

    private val circleControllers = mutableMapOf<String, CircleController>()

    fun addCircles(circlesToAdd: List<PlatformCircle>) = circlesToAdd.forEach(::addCircle)

    fun changeCircles(circlesToChange: List<PlatformCircle>) =
        circlesToChange.forEach(::changeCircle)

    fun removeCircles(circleIdsToRemove: List<String>) {
        circleIdsToRemove.forEach { circleControllers.remove(it)?.remove() }
    }

    fun dispose() {
        circleControllers.values.forEach(CircleController::remove)
        circleControllers.clear()
    }

    private fun addCircle(circle: PlatformCircle) {
        val circleBuilder = CircleBuilder()
        Convert.interpretCircleOptions(circle, circleBuilder)
        addCircle(circle.circleId, circleBuilder.build())
    }

    private fun addCircle(circleId: String, circleOptions: CircleOptions) {
        circleControllers.remove(circleId)?.remove()
        circleControllers[circleId] = CircleController(map.addCircle(circleOptions))
    }

    private fun changeCircle(circle: PlatformCircle) {
        circleControllers[circle.circleId]?.let { circleController ->
            Convert.interpretCircleOptions(circle, circleController)
        }
    }
}
