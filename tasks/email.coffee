#Installs the exim mail transport agent configuration
async = require "async"
control = require "control"
path = require "path"

copyConfig = (server, callback) ->
  from = path.join __dirname, "..", "deploy", "update-exim4.conf.conf"
  to = "/tmp"
  server.scp from, to, callback

updateConf = (server, callback) ->
  script = """#!/bin/sh -e
echo m-cm.net > /etc/mailname
mv /tmp/update-exim4.conf.conf /etc/exim4
update-exim4.conf
service exim4 restart
"""
  server.script script, true, callback, callback

email = (server) ->
  async.series [
    async.apply copyConfig, server
    async.apply updateConf, server
  ], (error) ->
      throw error if error

control.task "email", "Install and Configure the exim4 MTA", email
