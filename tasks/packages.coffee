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
  server.packages = conf.servers.staging.packages
  packages server, (error) ->
    throw error if error

module.exports = {packages}