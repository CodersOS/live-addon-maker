#!/bin/bash

sudo ./make-addon.sh *.iso examples/z-sources.list.squashfs \
  -c "sed -i=.live-addon 's/restricted$/restricted multiverse universe/' /etc/apt/sources.list"
  -c "apt-get update"
