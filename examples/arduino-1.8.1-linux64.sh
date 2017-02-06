#!/bin/bash

desktop=""

(
  cd /tmp
  wget -c https://downloads.arduino.cc/arduino-1.8.1-linux64.tar.xz || {
    echo "Could not download Arduino binaries."
    exit 1
  }
) || exit 1

sudo ./make-addon.sh *.iso examples/z-arduino-1.8.1-linux64.squashfs \
                     -A /tmp/arduino-1.8.1-linux64.tar.xz /opt/ \
                     -c "cd /opt/ && tar -xf arduino-1.8.1-linux64.tar.xz" \
                     -a examples/files/arduino-ide.desktop /usr/share/applications/
  
