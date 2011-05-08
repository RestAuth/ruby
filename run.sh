#!/bin/bash

TYPES="^>>|^\?>|=>"
#FLAGS="^CALLINFO|^HTTPCALL|REQUEST"
FLAGS="^CALLINFO|^HTTPCALL"

# with debug output
#irb userstest.rb
#irb groupstest.rb

# without debug output
irb userstest.rb | egrep -v "${TYPES}|${FLAGS}"
#irb groupstest.rb | egrep -v "${TYPES}|${FLAGS}"

