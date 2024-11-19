#!/bin/bash

# esse script cria um ping pong com a luminosidade com a permissao de adb ou root

adb shell settings put system screen_brightness 0

while true; do

    for ((i = 0; i <= 255; i=i+8)); do

	echo "BRILHO: $i"
        adb shell settings put system screen_brightness $i

    done

    for ((i = 255; i >= 0; i=i-8)); do

	echo "brilho: $i"
        adb shell settings put system screen_brightness $i

    done

done
