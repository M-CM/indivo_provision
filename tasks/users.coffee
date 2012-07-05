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
    script = "#!/bin/sh\n"
    script += "adduser --disabled-password "
    #Don't do --system since it makes their shell /bin/false
    #Which makes troubleshooting a pain
    #if user.system
    #  script += "--system --quiet "
    script += "--home /home/#{user.login} "
    script += "#{user.login}\n"
    for group in user.groups
      script += "addgroup #{user.login} #{group}\n"
    ops.push async.apply(runScript, script, server)
  async.series ops, callback

control.task "users", "Create OS user accounts", (server) ->
  server.user = "root"
  addUser conf.users, server, (error) ->
    throw error if error
    #sshKey server

module.exports = {addUser}
