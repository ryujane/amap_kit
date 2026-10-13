package com.github.amapkit.map

internal class MyLocationStyleController<T : Any>(
    private val applyStyle: (T) -> Unit,
    private val applyEnabled: (Boolean) -> Unit
) {
    private var retainedStyle: T? = null

    fun setStyle(style: T?) {
        if (style == null) return
        retainedStyle = style
        applyStyle(style)
    }

    fun setEnabled(enabled: Boolean) {
        applyEnabled(enabled)
        // Disabling location destroys the SDK layer, including its style.
        if (enabled) retainedStyle?.let(applyStyle)
    }

    fun clear() {
        retainedStyle = null
    }
}
