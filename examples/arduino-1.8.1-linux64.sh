#!/bin/bash

desktop="[Desktop Entry]
Type=Application
Name=Arduino IDE
GenericName=Arduino IDE
Comment=Open-source electronics prototyping platform
Exec=/opt/arduino-1.8.1/arduino
Icon=/opt/arduino-1.8.1/arduino/lib/icons/256x256/apps/arduino.png
Terminal=false
Categories=Development;IDE;Electronics;
MimeType=text/x-arduino;
Keywords=embedded electronics;electronics;avr;microcontroller;
StartupWMClass=processing-app-Base"

sudo ./make-addon.sh *.iso \
  examples/arduino-1.8.1-linux64.squashfs \
  -b 'mkdir -p /opt && cd /opt && wget https://downloads.arduino.cc/arduino-1.8.1-linux64.tar.xz' \
  bash -c "cd /opt/ && tar -xf arduino-1.8.1-linux64.tar.xz && cd arduino-1.8.1 && echo '$desktop' > /usr/share/applications/arduino-ide.desktop"
