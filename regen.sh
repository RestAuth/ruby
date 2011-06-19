#!/bin/sh

# remove old things
rm restauth-*.gem
gem uninstall restauth

# generate new gem
gem build restauth.gemspec

# install new gem
gem install --user-install restauth-*.gem
