#Installs an arbitrary list of Debian/Ubuntu packages as provided in the
#server.packages array of strings

conf = require "../conf"
control = require "control"

packages = (server, callback) ->
  packageList = server.packages.join " "
  script = """#!/bin/sh
PACKAGES='#{packageList}'
apt-get update
apt-get install --yes ${PACKAGES}
"""
  server.script script, true, callback

control.task "packages", "Install OS packages", (server) ->
  packages server, (error) ->
    throw error if error

module.exports = {packages}
