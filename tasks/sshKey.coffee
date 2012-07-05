#Copies your public SSH key to your corresponding remote account

conf = require "../conf"
control = require "control"
fs = require "fs"
path = require "path"


sshKey = (login, server, callback) ->
  keyPath = path.join process.env.HOME, ".ssh", "id_rsa.pub"
  fs.readFile keyPath, "utf-8", (error, key) ->
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
    server.script script

control.task "sshKey", "Copy sshkey to your remote user", (server) ->
  server.user = "root"
  sshKey process.env.USER, server

module.exports = {sshKey}
