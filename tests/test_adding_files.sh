#!/bin/bash

source test.sh

testcase "add file directly"
  addon -a adding_files_asd_with_content/asd /
  expect adding_files_asd_with_content "add file directly to /"

  addon -a adding_files_asd_with_content /
  expect adding_files_asd_with_content "add folder directly to /"

testcase "add but not to addon"
  addon -A adding_files_asd_with_content/asd /
  expect empty "add file directly to /"

  addon -A adding_files_asd_with_content /
  expect empty "add folder directly to /"

testcase "add files via command"
  addon -A adding_files_asd_with_content/asd / -c "[ -f /asd ] && echo -n > /asd"
  expect adding_files_empty_asd "add file directly to / and delete content"

  addon -A adding_files_empty_asd / -c "[ -f /asd ] && echo -n > /asd"
  expect adding_files_empty_asd "add folder directly to / and delete content"
