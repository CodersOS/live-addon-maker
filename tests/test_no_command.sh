#!/bin/bash

source test.sh

addon
expect empty "no commands create no files"
