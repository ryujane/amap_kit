package com.github.amapkit.map

import androidx.lifecycle.Lifecycle

fun interface LifecycleProvider {
    fun currentLifecycle(): Lifecycle?
}
