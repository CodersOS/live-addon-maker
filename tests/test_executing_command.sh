#!/bin/bash

source test.sh

testcase "add to files"
  addon -c "touch /asd"
  expect adding_files_empty_asd "touching file in root"

  addon -n -c "echo 'asdasd' >> /asd"
  expect adding_files_asd_with_content "adding content to file"

testcase "volatile commands"
  addon -C "touch /asd2"
  expect empty "touching file in root"

  addon -C "echo 'asdasd' >> /asd2"
  expect empty "adding content to file"

testcase "combine volatile and persistent commands"
  addon -C "touch /asd2" -c "cp /asd2 /asd"
  expect adding_files_empty_asd "touching file in root" -c "cp /asd2 /asd"

  addon -C "echo 'asdasd' >> /asd2" -c "cp /asd2 /asd"
  expect adding_files_asd_with_content "adding content to file"
