child_process = require "child_process"
control = require "control"
util = require "util"

#Run a shell script over ssh. Streams the script content to the remote
#ssh process's stdin thus no temporary files are necessary
control.controller.script = (script, sudo=false, callback) ->
  if typeof(sudo) == 'function'
    callback = sudo
    sudo = false
  args = ["#{@user}@#{@address}", "/bin/sh", "-s"]
  if sudo
    #Two -t options forces pseudo-tty allocation
    args.splice 1, 0, "sudo"
    #args.unshift ["-t", "-t"]...
  ssh = child_process.spawn "ssh", args
  ssh.on 'exit', (code) ->
    if code isnt 0
      return callback(new Error("script with ssh exited with #{code}"))
    callback() if callback
  ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.stderr.on "data", (chunk) -> process.stderr.write chunk.toString()
  ssh.stdin.write script
  ssh.stdin.end()

#Disable logging
control.controller.origLog = control.controller.log
control.controller.logOn = ->
  control.controller.log = control.controller.origLog
control.controller.logOff = ->
  control.controller.log = ->

upstart = (server, jobName, callback) ->
  jobName = "indivo_ui_server"
  confName = "#{jobName}.conf"
  from = path.join __dirname, "..", "deploy", "init", confName
  to = "/etc/init"
  upstart = fs.readFileSync from
  script = """#!/bin/sh -e
cat << EOF > /etc/init/#{confName}
#{upstart}
EOF
initctl reload-configuration
start #{jobName}
"""

module.exports = {upstart}
