#!/bin/sh

# remove old things
rm restauth-0.2.gem
gem uninstall restauth

# generate new gem
gem build restauth.gemspec

# install new gem
gem install --user-install restauth-0.2.gem
