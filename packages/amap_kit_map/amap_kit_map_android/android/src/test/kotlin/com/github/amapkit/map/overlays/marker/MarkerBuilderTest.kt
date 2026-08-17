package com.github.amapkit.map.overlays.marker

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MarkerBuilderTest {
    @Test
    fun consumeTapEventsIsRetained() {
        val builder = MarkerBuilder(markerId = "marker", clusterManagerId = null)

        builder.setConsumeTapEvents(true)

        assertTrue(builder.consumeTapEvents)
    }

    @Test
    fun infoWindowTextIsAppliedToMarkerOptions() {
        val builder = MarkerBuilder(markerId = "marker", clusterManagerId = null)

        builder.setTitle("title")
        builder.setSnippet("snippet")

        assertEquals("title", builder.build().title)
        assertEquals("snippet", builder.build().snippet)
    }
}
