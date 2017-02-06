#!/bin/bash

source "test.sh"

testcase "/dev"
  addon -c 'ls /dev > /dev-list'
  expect '[ -n "`cat dev-list`" ]' "The host devices are mapped to the chroot."
