from fabric.api import put
from fabric.api import sudo
from fabric.api import task
import makitso
import os

EMAIL_SCRIPT = """#!/bin/sh -e
echo m-cm.net > /etc/mailname
update-exim4.conf
service exim4 restart
"""


@task
def email():
    """Install and configure the exim4 mail transport agent"""
    makitso.packages.apt("exim4-daemon-light")
    config_path = os.path.join("deploy", "exim4", "update-exim4.conf.conf")
    put(config_path, "/etc/exim4/update-exim4.conf.conf", use_sudo=True)
    makitso.util.script(EMAIL_SCRIPT, sudo, "Configure Exim Email Server")
