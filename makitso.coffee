#!/usr/bin/env coffee
_ = require "underscore"
conf = require "./conf"
control = require "control"
require "./tasks/easyInstall"
require "./tasks/email"
require "./tasks/packages"
provision = require "./tasks/provision"
require "./tasks/indivoDB"
require "./tasks/indivoServer"
require "./tasks/indivoUIServer"
require "./tasks/users"
require "./tasks/sshKey"
tasklib = require "./tasks/tasklib"

exit = process.exit

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
  exit()

err = (message) -> process.stderr.write "#{message}\n"
try
  control.begin()
catch error
  if error.message?.indexOf("No task named") == 0
    names = _.keys(conf.servers).join(", ")
    err "Error: Server name must be one of: #{names}"
    exit 2
  else if error.message?.indexOf("No task name") == 0
    err "Usage: ./do <serverName> <taskName>"
    exit 11
  else
    err error.message
    exit 12
