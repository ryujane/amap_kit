package com.github.amapkit.map.overlays.ground

import com.amap.api.maps.model.LatLng
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class GroundOverlayBuilderTest {
    @Test
    fun positionAndDisplayOptionsAreApplied() {
        val builder = GroundOverlayBuilder()

        builder.setPosition(LatLng(30.0, 120.0), 100f, 80f)
        builder.setAnchor(0.25f, 0.75f)
        builder.setBearing(45f)
        builder.setTransparency(0.4f)
        builder.setZIndex(3f)
        builder.setVisible(false)

        val options = builder.build()
        assertEquals(30.0, options.location.latitude, 0.001)
        assertEquals(120.0, options.location.longitude, 0.001)
        assertEquals(100f, options.width, 0.001f)
        assertEquals(80f, options.height, 0.001f)
        assertEquals(0.25f, options.anchorU)
        assertEquals(0.75f, options.anchorV)
        assertEquals(45f, options.bearing)
        assertEquals(0.4f, options.transparency)
        assertEquals(3f, options.zIndex)
        assertFalse(options.isVisible)
    }
}
