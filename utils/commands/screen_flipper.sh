#!/bin/sh
# rodar a tela:
while true; do for i in 0 1 2 3; do settings put system user_rotation $i; sleep 2; done; done
