#!/bin/bash
sudo ./make-addon.sh *.iso examples/z-flash.squashfs \
                     -C "sed -i 's/restricted$/restricted multiverse universe/' /etc/apt/sources.list" \
                     -C 'apt-get update' \
                     -c 'apt-get -y install flashplugin-installer'
