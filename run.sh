#!/bin/bash

TYPES="^>>|^\?>|=>"
FLAGS="^CALLINFO|^HTTPCALL"

# with debug output
#irb -r ./RestAuth.rb test.rb

# without debug output
irb -r ./RestAuth.rb test.rb | egrep -v "${TYPES}|${FLAGS}"

