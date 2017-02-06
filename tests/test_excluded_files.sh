#!/bin/bash

source "test.sh"

testcase "temporary files are excluded"
  addon -c "touch /tmp/asd"
  expect empty "The tmp folder and all files are ignored"
