#!/usr/bin/env coffee
conf = require "./conf"
control = require "control"
require "./tasks/easyInstall"
require "./tasks/packages"
provision = require "./tasks/provision"
require "./tasks/indivoDB"
require "./tasks/user"
tasklib = require "./tasks/tasklib"

control.task "staging", "Staging server", ->
  staging = Object.create control.controller
  staging.address = conf.servers.staging.hostname
  staging.user = process.env.USER
  [staging]

control.task "check", "Check ssh connectivity", (server) ->
  server.script "date && uptime"

control.task "checksudo", "Check ssh connectivity", (server) ->
  server.script "date && uptime", true

provision.on "done", ->
  process.exit()
control.begin()
