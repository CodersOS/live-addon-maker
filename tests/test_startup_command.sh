#!/bin/bash

source test.sh

link="etc/systemd/system/default.target.wants/example.service"
file1="/etc/systemd/system/example.service"
file2="/usr/local/bin/start-example-service.sh"

test_expectations() {
  expect example_startup_script "touching file in root"
  expect "test -L $link" \
         "Link $link exists"
  expect '[ "`readlink '"$link"'`" == "'$file1'" ]' \
         "Link has correct target."
}

testcase "example startup script"
  addon -s "example" "touch /started"
  test_expectations

testcase "startup script files are available"
  addon -s "example" "touch " -c "echo -n /started >> '$file2'"
  test_expectations

testcase "Several startup commands"
  addon -s "test1" "testcommand 1" -s "test2" "testcommand 2"
  expect true "Command worked."