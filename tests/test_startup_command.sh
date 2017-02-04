#!/bin/bash

source test.sh

testcase "example startup script"
  addon -s "example" "touch /started"
  expect example_startup_script "touching file in root"
  expect "test -L etc/systemd/system/default.target.wants/example.service" \
         "Link etc/systemd/system/default.target.wants/example.service exists"

testcase "startup script files are available"
  addon -s "example" "touch " -c "echo -n /started > /usr/local/bin/start-example-service.sh"
  expect example_startup_script "modifying startup file"
