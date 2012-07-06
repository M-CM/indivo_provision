#Creates or updates a linux user account

_ = require "underscore"
async = require "async"
conf = require "../conf"
control = require "control"
fs = require "fs"
path = require "path"

runScript = (script, server, callback) ->
  console.log script
  server.script script, callback

addUser = (users, server, callback) ->
  ops = []
  for user in users
    script = """#!/bin/sh
adduser --disabled-password --quiet --gecos '' --home /home/#{user.login} #{user.login} || /bin/true\n
"""
    for group in user.groups
      script += "addgroup #{user.login} #{group}\n"
    ops.push async.apply(runScript, script, server)
  async.series ops, callback

sudoers = (server, callback) ->
  from = path.join __dirname, "..", "deploy", "sudoers"
  server.scp from, "/etc/sudoers", callback, callback

control.task "users", "Create OS user accounts", (server) ->
  server.user = "root"
  async.series [
    async.apply addUser, conf.users, server
    async.apply sudoers, server
  ], (error) ->
    throw error if error

module.exports = {addUser, sudoers}
