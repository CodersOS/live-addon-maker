#!/bin/bash

cd "`dirname \"$0\"`"

source test.sh

for file in test_*.sh; do
  testcase ""
  source "$file"
done

summarize

