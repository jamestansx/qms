#!/bin/bash

set -xe

sudo chmod a+rw $1
arduino-cli compile -b esp32:esp32:esp32cam:PartitionScheme=huge_app --library "quirc/lib"
arduino-cli upload  -b esp32:esp32:esp32cam:PartitionScheme=huge_app -p $1
