package com.github.amapkit.map

import kotlin.test.Test
import kotlin.test.assertNull
import kotlin.test.assertSame

class MyLocationStyleControllerTest {
    private class Layer {
        var style: Any? = null
        val controller = MyLocationStyleController<Any>(
            { style = it },
            { enabled -> if (!enabled) style = null }
        )
    }

    @Test
    fun restoresStyleAfterInitiallyDisabledAndRepeatedToggles() {
        val layer = Layer()
        val style = Any()
        layer.controller.setStyle(style)
        repeat(3) {
            layer.controller.setEnabled(false)
            assertNull(layer.style)
            layer.controller.setEnabled(true)
            assertSame(style, layer.style)
        }
    }

    @Test
    fun retainsLatestStyleAcrossDisableAndNullUpdates() {
        val layer = Layer()
        layer.controller.setStyle(Any())
        layer.controller.setEnabled(false)
        val latest = Any()
        layer.controller.setStyle(latest)
        layer.controller.setStyle(null)
        layer.controller.setEnabled(false)
        layer.controller.setEnabled(true)
        assertSame(latest, layer.style)
    }

    @Test
    fun keepsInstancesIsolatedAndClearsRetainedStyle() {
        val first = Layer()
        val second = Layer()
        first.controller.setStyle(Any())
        second.controller.setEnabled(true)
        assertNull(second.style)
        first.controller.setEnabled(false)
        first.controller.clear()
        first.controller.setEnabled(true)
        assertNull(first.style)
    }
}
