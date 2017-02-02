#!/bin/bash
sudo ./make-addon.sh *.iso examples/idle-python3.5.squashfs -b 'apt-get update' bash -c 'apt-get -y install idle-python3.5'
