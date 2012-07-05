#!/usr/bin/env coffee
_ = require "underscore"
conf = require "./conf"
control = require "control"
require "./tasks/easyInstall"
require "./tasks/packages"
provision = require "./tasks/provision"
require "./tasks/indivoDB"
require "./tasks/indivoServer"
require "./tasks/indivoUIServer"
require "./tasks/users"
require "./tasks/sshKey"
tasklib = require "./tasks/tasklib"

for name, settings of conf.servers
  control.task name, "", ->
    server = Object.create control.controller
    _.extend server, settings
    server.configName = name
    [server]

control.task "check", "Check ssh connectivity", (server) ->
  server.script "date && uptime"

control.task "checksudo", "Check ssh connectivity", (server) ->
  server.script "date && uptime", true

provision.on "done", ->
  process.exit()
control.begin()
