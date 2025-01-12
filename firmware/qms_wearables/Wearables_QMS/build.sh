#!/bin/bash

set -xe

sudo chmod a+rw $1
arduino-cli compile -b esp32:esp32:esp32:PartitionScheme=huge_app
arduino-cli upload  -b esp32:esp32:esp32:PartitionScheme=huge_app -p $1
