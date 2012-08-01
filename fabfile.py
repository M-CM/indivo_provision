from ConfigParser import SafeConfigParser
import getpass
import os
import re
import sys

#Try to load our third party pip modules
#if they aren't yet installed, attempt to install them on the fly automatically
try:
    from libcloud.compute.deployment import MultiStepDeployment
except ImportError:
    pip = os.path.join("python", "bin", "pip")
    exit_code = os.system("%s install -r requirements.txt" % pip)
    if exit_code != 0:
        sys.exit(exit_code)

BASE_DIR = os.path.dirname(__file__)
os.chdir(BASE_DIR or ".")

sys.path.append("./tasks")

#from fabric.api import local
#from fabric.api import sudo
from exim import email
from fabric.api import env
from fabric.api import execute
from fabric.api import run
from fabric.api import task
from fabric.contrib.files import settings
from indivo_server import indivo_server
from indivo_ui_server import indivo_ui_server
from libcloud.compute.deployment import MultiStepDeployment
from libcloud.compute.deployment import ScriptDeployment
from libcloud.compute.deployment import SSHKeyDeployment
from makitso.cloud import choose_cloud_option
from makitso.cloud import cloud_connect
from makitso.cloud import get_node
from makitso.cloud import set_root_password
from makitso.server_conf import server_task
from makitso.util import dot
from makitso.util import out
from makitso.util import script
import makitso.cloud as cloud
import makitso.debian as debian
import makitso.packages as packages
import makitso.server_conf as server_conf
import makitso.util as util


SERVER_CONF_PATH = "conf/servers.json"
IMAGE_RE = re.compile("^Ubuntu 12.04", re.I)
SIZE_RE = re.compile("^256 ")


########## cloud tasks ##########
@task
def provision():
    """Create a new cloud server instance"""
    if "server" not in env:
        util.exit("Please specify a target server")
    conn = cloud_connect()
    image = choose_cloud_option(conn.list_images, IMAGE_RE, "image")
    size = choose_cloud_option(conn.list_sizes, SIZE_RE, "size")
    root_password = getpass.getpass(
        "Choose a root password for the new server: ")
    ssh_key = util.get_ssh_key()
    users = ScriptDeployment(debian.make_user_script(os.environ["USER"], ssh_key))

    # a task that first installs the ssh key, and then runs the script
    msd = MultiStepDeployment([SSHKeyDeployment(ssh_key), users])
    out("Creating %s (%s) on %s" % (image.name, size.name, image.driver.name))
    node = conn.deploy_node(name=env.server["name"], image=image, size=size,
        deploy=msd)
    out(node)
    while get_node(node.uuid).state != 0:
        dot()
    out("Node is up.")
    env.host_string = node.public_ips[0]
    conf = server_conf.read(SERVER_CONF_PATH)
    conf[env.server["label"]]["hostname"] = node.public_ips[0]
    server_conf.write(conf, SERVER_CONF_PATH)
    set_root_password(node.uuid, root_password)
    #Make my shell zsh
    with settings(user="root"):
        packages.apt("zsh")
        login = os.environ["USER"]
        util.script("chsh --shell /bin/zsh " + login, name="Use zshell")
        out("Please set a password for %s on %s" % (login, env.host_string))
        run("passwd " + login)
    return node


@task
def ssh_key():
    """Install your SSH public key as an authorized key on the server"""
    key = util.get_ssh_key()
    login = os.environ["USER"]
    script_text = """KEYS=~%(login)s/.ssh/authorized_keys
DIR=$(dirname "${KEYS}")
mkdir -p "${DIR}"
touch "${KEYS}"
chown '%(login)s:%(login)s' "${DIR}" "${KEYS}"
chmod 700 "${DIR}"
chmod 600 "${KEYS}"
cat <<EOF>> "${KEYS}"
%(key)s
EOF
""" % locals()
    with settings(user="root"):
        script(script_text, "install ssh key to " + login)


@task
def servers():
    """Show configured target servers"""
    util.print_json(server_conf.read(SERVER_CONF_PATH))


@task
def full_build():
    """Create a new RackSpace VM and install Indivo X from scratch"""
    execute(provision)
    execute(email)
    execute(indivo_server)
    execute(indivo_ui_server)

for name in server_conf.read(SERVER_CONF_PATH).keys():
    setattr(sys.modules[__name__], name, server_task(name))

env.config = SafeConfigParser({"installPrefix": "/web"})
env.config.read("conf/settings.conf")
