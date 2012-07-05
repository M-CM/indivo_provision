fs = require "fs"
path = require "path"

upstart = (server, jobName, callback) ->
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

module.exports = upstart
