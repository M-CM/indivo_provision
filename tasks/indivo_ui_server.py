from fabric.api import env
from fabric.api import put
from fabric.api import sudo
from fabric.api import task
from makitso import packages
import makitso
import os


INSTALL_SCRIPT = """#!/bin/sh -e
########## download ##########
BASEHOST="%(siteurl)s"
DIST_URL="%(uidisturl)s"
PREFIX="%(installprefix)s"

ARCHIVE=$(basename "${DIST_URL}")
cd /tmp
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

########## configuration ##########
cp settings.py.default settings.py
cat << EOF >> settings.py
########## BEGIN M-CM CUSTOMIZATION ##########
#Everything above this should be a clean copy of the settings.py.default file
#From here down are just what is customized for M-CM's particular installation

INDIVO_UI_SERVER_BASE = "${BASEHOST}"
# Make this unique, and don't share it with anybody.
SECRET_KEY = 'M-CMDEVELOPMENT-INDIVO-SECRET-KEY'

# URL prefix (where indivo_server will be accessible from the web)
SITE_URL_PREFIX = "${BASEHOST}"
EOF

########## permissions ##########
%(permissions)s
chmod u+w sessions

########## apache setup ##########
a2enmod wsgi
a2enmod ssl
a2dissite default
a2ensite portal.m-cm.net
service apache2 reload
"""


@task
def indivoUIServer():
    """Install the Indivo X 2.0 UI Server and its prerequisites"""
    packages.apt([
        "curl",  # Scripts use this to download files from the web
        "apache2-mpm-prefork",
        "libapache2-mod-wsgi"
    ])
    sitesPath = os.path.join("deploy", "apache2", "sites-available", "*")
    put(sitesPath,  "/etc/apache2/sites-available", use_sudo=True, mode=0400)

    vars = dict(env.config.items("indivo"))
    vars["permissions"] = makitso.util.permissions("www-data:sudo", 444, 555)
    makitso.util.script(
        INSTALL_SCRIPT % vars, sudo, "Install Indivo UI Server")
