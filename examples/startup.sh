#!/bin/bash
sudo ./make-addon.sh *.iso examples/z-startup.squashfs \
                     -s "touch /started"
