package com.github.amapkit.map

import com.amap.api.maps.AMap

interface AmapMapListener : AMap.OnMapClickListener, AMap.OnMapLongClickListener, AMap.OnCameraChangeListener{
}