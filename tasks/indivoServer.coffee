#Downloads and installs the indivo server
#Configures the settings.py and util/indivo_data.xml configuration files
async = require "async"
conf = require "../conf"
control = require "control"
fs = require "fs"
path = require "path"
permissions = require "../lib/permissions"
upstart = require "../lib/upstart"

installServer = (server, callback) ->
  script = """#!/bin/sh -e
########## download ##########
cd /tmp
SERVER_DIST_URL="#{conf.indivo.serverDistURL}"
ARCHIVE=$(basename "${SERVER_DIST_URL}")
PREFIX="#{conf.indivo.installPrefix}"
BASE="${PREFIX}/indivo_server"
curl --silent --remote-name "${SERVER_DIST_URL}"

########## extract ##########
if [ -d "${BASE}" ]; then
  mv "${BASE}" "${BASE}.old.$$"
fi
mkdir -p "${PREFIX}"
tar xzf "${ARCHIVE}" -C "${PREFIX}"
rm "${ARCHIVE}"
cd "${BASE}"

########## settings ##########
cp settings.py.default settings.py
cat << EOF >> settings.py
########## BEGIN M-CM CUSTOMIZATION ##########
#Everything above this should be a clean copy of the settings.py.default file
#From here down are just what is customized for M-CM's particular installation
ADMINS = ('Christy Collins', 'christy@m-cm.net')

# Make this unique, and don't share it with anybody.
SECRET_KEY = 'M-CMDEVELOPMENT-INDIVO-SECRET-KEY'

# URL prefix (where indivo_server will be accessible from the web)
SITE_URL_PREFIX = "http://#{server.address}:8000"
UI_SERVER_URL = "http://#{server.address}"


# Storage Settings
DATABASES = {
    'default':{
        'ENGINE':'django.db.backends.postgresql_psycopg2', # '.postgresql_psycopg2', '.mysql', or '.oracle'
        'NAME':'indivo',
        'USER':'indivo',
        'PASSWORD':'indivo',
        'HOST':'127.0.0.1', # Set to empty string for localhost.
        'PORT':'', # Set to empty string for default.
        },
}
SEND_MAIL = True # Turn email on at all?
EMAIL_HOST = "localhost"
EMAIL_PORT = 25
EMAIL_FROM_ADDRESS = "M-CM Indivo <support@m-cm.net>"
EMAIL_SUPPORT_ADDRESS = "support@m-cm.net"
EMAIL_SUPPORT_NAME = "M-CM Indivo Support"
EOF

########## permissions ##########
touch indivo.log
#{permissions "indivo:sudo"}
chmod u+w indivo.log
#Need group write so we can copy XML file and reset script into place
chmod g+w utils
chmod g+w utils/reset.py
"""
  server.script script, true, callback

copyConfig = (server, callback) ->
  from = path.join __dirname, "..", "conf", "indivo_data.xml"
  to = path.join conf.indivo.installPrefix, "indivo_server", "utils"
  server.scp from, to, ->
    from = path.join __dirname, "..", "utils", "reset.py"
    server.scp from, to, callback, callback

resetDB = (server, callback) ->
  script = """#!/bin/sh -e
cd "#{conf.indivo.installPrefix}/indivo_server"
#Can't use the stock reset.py. I send in a pull request for a fix
#https://github.com/chb/indivo_server/pull/18
su -c 'echo yes | python utils/reset.py' indivo
"""
  server.script script, true, callback, callback

indivoServer = (server) ->
  async.series [
    async.apply installServer, server
    async.apply copyConfig, server
    async.apply resetDB, server
    async.apply upstart, server, "indivo_server"
  ], (error) ->
      throw error if error

control.task "indivoServer", "Install the Indivo Server Software", indivoServer
