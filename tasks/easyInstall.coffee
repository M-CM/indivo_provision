#Installs python easy_install packages as provided in an array of strings in the
#server.easyInstall property

conf = require "../conf"
control = require "control"

easyInstall = (server, callback) ->
  packageList = server.easyInstall.join " "
  script = """#!/bin/sh
PACKAGES='#{packageList}'
easy_install ${PACKAGES}
"""
  server.script script, true, callback

control.task "easyInstall", "Install Easy Install Python Packages", (server) ->
  easyInstall server, (error) ->
    throw error if error

module.exports = {easyInstall}
