#Copies your public SSH key to your corresponding remote account

conf = require "../conf"
control = require "control"
fs = require "fs"
path = require "path"

usage = """Usage: ./do <serverName> sshKey [login] [keyPath]
\tlogin defaults to your current username
\tkeyPath defaults to ~/.ssh/id_rsa.pub
"""
err = (message, exitCode=10) ->
  process.stderr.write "#{message}\n"
  process.exit exitCode

control.task "sshKey", "Copy sshkey to your remote user", (server, login, keyPath) ->
  login = login or process.env.USER
  keyPath = keyPath or path.join process.env.HOME, ".ssh", "id_rsa.pub"
  fs.readFile keyPath, "utf-8", (error, key) ->
    if error?.code == "ENOENT"
      err """No Public key at #{keyPath}. Aborting.
You may provide an alternate path on the command line.
\n""" + usage
    script = """#!/bin/sh -e
TARGET_USER="#{login}"
cd ~#{login}
umask 077
KEY='#{key}'
SSH=".ssh"
[ -d "${SSH}" ] || mkdir "${SSH}"
chown "${TARGET_USER}:${TARGET_USER}" "${SSH}"
echo "${KEY}" >> "${SSH}/authorized_keys"
chown "${TARGET_USER}:${TARGET_USER}" "${SSH}/authorized_keys"
echo "Key '$(echo ${KEY} | cut -d " " -f 3-)' authorized to log in as ${TARGET_USER}"
"""
    server.user = "root"
    server.script script, ->
