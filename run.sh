#!/bin/bash

TYPES="^>>|^\?>|=>"
#FLAGS="^CALLINFO|^HTTPCALL|REQUEST"
FLAGS="^CALLINFO|^HTTPCALL"

# with debug output
#irb -r ./RestAuth.rb userstest.rb
#irb -r ./RestAuth.rb groupstest.rb

# without debug output
irb -r ./RestAuth.rb userstest.rb | egrep -v "${TYPES}|${FLAGS}"
#irb -r ./RestAuth.rb groupstest.rb | egrep -v "${TYPES}|${FLAGS}"

