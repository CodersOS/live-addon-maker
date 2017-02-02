#!/bin/bash
sudo ./make-addon.sh *.iso examples/flash.squashfs -b 'apt-get update' bash -c 'apt-get -y install flashplugin-installer'
