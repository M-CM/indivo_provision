#Downloads and installs the indivo UI server
#Configures the settings.py and util/indivo_data.xml configuration files
async = require "async"
conf = require "../conf"
control = require "control"
indivoServer = require "./indivoServer"
permissions = require "../lib/permissions"
upstart = require "../lib/upstart"

installServer = (server, callback) ->
  script = """#!/bin/sh -e
########## download ##########
cd /tmp
DIST_URL="#{conf.indivo.UIDistURL}"
ARCHIVE=$(basename "${DIST_URL}")
PREFIX="#{conf.indivo.installPrefix}"
BASE="${PREFIX}/indivo_ui_server"
curl --silent --remote-name "${DIST_URL}"
if [ -d "${BASE}" ]; then
  mv "${BASE}" "${BASE}.old.$$"
fi

########## extract ##########
mkdir -p "${PREFIX}"
tar xzf "${ARCHIVE}" -C "${PREFIX}"
rm "${ARCHIVE}"
cd "${BASE}"

########## permissions ##########
#{permissions "indivo:sudo"}

########## configuration ##########
cp settings.py.default settings.py
BASEHOST="#{server.address}"
cat << EOF >> settings.py
########## BEGIN M-CM CUSTOMIZATION ##########
#Everything above this should be a clean copy of the settings.py.default file
#From here down are just what is customized for M-CM's particular installation

INDIVO_UI_SERVER_BASE = "http://${BASEHOST}"
# Make this unique, and don't share it with anybody.
SECRET_KEY = 'M-CMDEVELOPMENT-INDIVO-SECRET-KEY'

# URL prefix (where indivo_server will be accessible from the web)
SITE_URL_PREFIX = "http://${BASEHOST}"
EOF
"""
  server.script script, true, callback


indivoUIServer = (server) ->
  async.series [
    async.apply installServer, server
    async.apply upstart, server, "indivo_ui_server"
  ], (error) ->
      throw error if error

description = "Install the Indivo UI Server Software"
control.task "indivoUIServer", description, indivoUIServer

module.exports = {indivoUIServer}
