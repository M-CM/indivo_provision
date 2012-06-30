#Creates or updates a linux user account

control = require "control"
fs = require "fs"
path = require "path"

#TODO can't set login shell to zsh until zsh is installed
user = (server, callback) ->
  groups = "sudo"
  login = "plyons"
  password = "$6$bNqJ1oCE$qgeMw1MYPF.4v4UdlyHUcm9CfKxbdL14RC7Hu2wTeH2qnEYF0Yf5uaZ2pef2mR4OMlVkDQ3En3cuyXZCBYY.t1"
  shell = "/bin/bash"
  script = """#!/bin/sh
GROUPS='#{groups}'
PASSWORD='#{password}'
LOGIN_SHELL='#{shell}'
LOGIN='#{login}'
useradd --create-home --groups "${GROUPS}" --password "${PASSWORD}" \\
    --shell "${LOGIN_SHELL}" --user-group "${LOGIN}"
EXIT_CODE=$?
#TODO make this idempotent
echo '%sudo  ALL=NOPASSWD: ALL' >> /etc/sudoers
case ${EXIT_CODE} in
    0)
        echo "user ${LOGIN} created"
    ;;
    9)
        #login already exits. Modify it.
        usermod --groups "${GROUPS}" --password "${PASSWORD}" \\
        --shell "${LOGIN_SHELL}" "${LOGIN}"
        echo "user ${LOGIN} updated"
    ;;
    *)
        exit ${EXIT_CODE}
    ;;
esac
"""
  server.script script, callback

sshKey = (server, callback) ->
  keyPath = path.join process.env.HOME, ".ssh", "id_rsa.pub"
  fs.readFile keyPath, "utf-8", (error, key) ->
    script = """#!/bin/sh
umask 077
KEY='#{key}'
SSH=".ssh"
[ -d "${SSH}" ] || mkdir "${SSH}"
echo "${KEY}" >> "${SSH}/authorized_keys"
echo "Key '$(echo ${KEY} | cut -d " " -f 3-)' authorized to log in as ${USER}"
"""
    server.script script, callback

control.task "user", "Create a system user account", (server) ->
  server.user = "root"
  user server, (error) ->
    throw error if error
    server.user = process.env.USER
    sshKey server

module.exports = {sshKey, user}
