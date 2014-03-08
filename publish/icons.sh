#!/bin/bash
(
cd app/img
convert -size 152x152 sources/touch-icon.png touch-icon-ipad-retina.png 
convert -size 120x120 sources/touch-icon.png touch-icon-iphone-retina.png 
convert -size 76x76 sources/touch-icon.png touch-icon-ipad.png 
convert -size 60x60 sources/touch-icon.png touch-icon-iphone.png
convert -size 120x120 sources/touch-icon.png touch-icon-android.png
convert -size 196x196 sources/touch-icon.png touch-icon-android-highres.png
)