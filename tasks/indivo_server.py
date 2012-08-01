from fabric.api import task
from fabric.api import env
from fabric.api import put
from fabric.api import sudo
from fabric.api import run
from fabric.context_managers import cd
from makitso import packages
from makitso.debian import make_upstart_script
from makitso.debian import make_user_script
import makitso
import os


DB_RESET_SCRIPT = """#!/bin/sh -e
cat << EOF >> /etc/postgresql/9.1/main/pg_hba.conf
#Added for M-CM Indivo X Server Configuration
local   all             all                                     md5
EOF
service postgresql restart
su postgres -c psql <<'EOF'
DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'indivo') THEN

      CREATE ROLE indivo LOGIN PASSWORD 'indivo' SUPERUSER;
   END IF;
END
$body$
EOF
su postgres -c 'dropdb indivo' 2>/dev/null || /bin/true
su postgres -c 'createdb -O indivo indivo'
"""

SERVER_INSTALL_SCRIPT = """#!/bin/sh -e
########## download ##########
cd /tmp
SERVER_DIST_URL="%(serverdisturl)s"
ARCHIVE=$(basename "${SERVER_DIST_URL}")
PREFIX="%(installprefix)s"
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
SITE_URL_PREFIX = "http://localhost:8000"
UI_SERVER_URL = "%(siteurl)s"


# Storage Settings
DATABASES = {
    'default':{
        # '.postgresql_psycopg2', '.mysql', or '.oracle'
        'ENGINE':'django.db.backends.postgresql_psycopg2',
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
%(permissions)s
chmod u+w indivo.log
#Need group write so we can copy XML file and reset script into place
chmod g+w utils
chmod g+w utils/reset.py
chmod g+w indivo.log
"""


@task
def indivo_server():
    """Install the Indivo X 2.0 Back End Server and its prerequisites"""
    packages.apt([
        "curl",  # Scripts use this to download files from the web
        "postgresql",  # database
        "python-django",  # app server
        "python-lxml",
        "python-psycopg2",  # Django->PostgreSQL
        "python-setuptools"
    ])
    packages.easy_install([
        "Markdown",
        "python-dateutil",
        "rdflib",
        "South"
    ])
    makitso.util.script(make_user_script("indivo"), sudo, "Create indivo user")
    makitso.util.script(DB_RESET_SCRIPT, sudo, "Reset Indivo DB")

    vars = dict(env.config.items("indivo"))
    vars["permissions"] = makitso.util.permissions("indivo:sudo")
    makitso.util.script(
        SERVER_INSTALL_SCRIPT % vars, sudo, "Install Indivo Server")
    base = os.path.join(env.config.get("indivo", "installprefix"),
        "indivo_server")
    utils = os.path.join(base, "utils")
    put("deploy/indivo/indivo_data.xml", utils, use_sudo=True)
    put("deploy/indivo/reset.py", utils, use_sudo=True)
    with cd(base):
        run("echo yes | python utils/reset.py")
    upstartPath = os.path.join("deploy", "init", "indivo_server.conf")
    makitso.util.script(
        make_upstart_script(upstartPath),
        sudo,
        "Configure upstart for Indivo Server")
