#!/bin/sh
# Manter a tela de cabeca para baixo

while true; do
	if [ $(settings get system user_rotation) -eq 1 ];then
		adb shell settings put system user_rotation 2
	fi
done
