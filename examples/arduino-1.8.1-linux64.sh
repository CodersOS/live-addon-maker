#!/bin/bash
sudo ./make-addon.sh *.iso \
  examples/arduino-1.8.1-linux64.squashfs \
  -b 'mkdir -p /opt && cd /opt && wget https://downloads.arduino.cc/arduino-1.8.1-linux64.tar.xz' \
  bash -c 'cd /opt/ && tar -xf arduino-1.8.1-linux64.tar.xz && cd arduino-1.8.1 && ./install.sh'
