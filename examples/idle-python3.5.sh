#!/bin/bash
sudo ./make-addon.sh *.iso examples/idle-python3.5.squashfs \
                     -C 'apt-get update' \
                     -c 'apt-get -y install idle-python3.5'
