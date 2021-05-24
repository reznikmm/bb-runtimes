#!/bin/bash

ALL="stm32f4 stm32f429disco stm32f469disco stm32f746disco stm32756geval \
     stm32f769disco samg55 sam4s samv71 openmv2 rpi3 rpi2 \
     cortex-m0 cortex-m0p cortex-m1 cortex-m3 cortex-m4 cortex-m4f \
     cortex-m7f cortex-m7df cortex-m23 cortex-m33f cortex-m33df"

if [ ! -d ../embedded-runtimes ]; then
    echo "Cannot find embedded-runtimes"
    exit 1
fi

rm -rf ../embedded-runtimes/BSPs

./build-rts.py --bsps-only --output=../embedded-runtimes $ALL
