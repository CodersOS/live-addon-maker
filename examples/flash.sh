#!/bin/bash
sudo ./make-addon.sh *.iso examples/flash.squashfs \
                     -C 'apt-get update' \
                     -c 'apt-get -y install flashplugin-installer'
