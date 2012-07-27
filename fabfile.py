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
    exitCode = os.system("%s install -r requirements.txt" % pip)
    if exitCode != 0:
        sys.exit(exitCode)

BASE_DIR = os.path.dirname(__file__)
os.chdir(BASE_DIR or ".")

sys.path.append("./tasks")

#from fabric.api import local
#from fabric.api import sudo
from indivo_server import indivoServer
from indivo_ui_server import indivoUIServer
from exim import email
from fabric.api import env
from fabric.api import execute
from fabric.api import run
from fabric.api import task
from fabric.contrib.files import settings
from libcloud.compute.deployment import MultiStepDeployment
from libcloud.compute.deployment import ScriptDeployment
from libcloud.compute.deployment import SSHKeyDeployment
from makitso.cloud import chooseCloudOption
from makitso.cloud import cloudConnect
from makitso.cloud import getNode
from makitso.cloud import setRootPassword
from makitso.server_conf import getServerConf
from makitso.server_conf import ServerTask
from makitso.server_conf import setServerConf
from makitso.util import dot
from makitso.util import out
from makitso.util import script
import makitso.cloud as cloud
import makitso.debian as debian
import makitso.packages as packages
import makitso.util as util


SERVER_CONF_PATH = "conf/servers.json"
IMAGE_RE = re.compile("^Ubuntu 12.04", re.I)
SIZE_RE = re.compile("^256 ")


########## cloud tasks ##########
@task
def provision():
    """Create a new cloud server instance"""
    conn = cloudConnect()
    image = chooseCloudOption(conn.list_images, IMAGE_RE, "image")
    size = chooseCloudOption(conn.list_sizes, SIZE_RE, "size")
    rootPassword = getpass.getpass(
        "Choose a root password for the new server: ")
    sshKey = util.getSSHKey()
    users = ScriptDeployment(debian.makeUserScript(os.environ["USER"], sshKey))

    # a task that first installs the ssh key, and then runs the script
    msd = MultiStepDeployment([SSHKeyDeployment(sshKey), users])
    out("Creating %s (%s) on %s" % (image.name, size.name, image.driver.name))
    node = conn.deploy_node(name=env.server["name"], image=image, size=size,
        deploy=msd)
    out(node)
    while getNode(node.uuid).state != 0:
        dot()
    out("Node is up.")
    env.host_string = node.public_ips[0]
    conf = getServerConf(SERVER_CONF_PATH)
    conf[env.server["label"]]["hostname"] = node.public_ips[0]
    setServerConf(conf, SERVER_CONF_PATH)
    setRootPassword(node.uuid, rootPassword)
    #Make my shell zsh
    with settings(user="root"):
        packages.apt("zsh")
        login = os.environ["USER"]
        util.script("chsh --shell /bin/zsh " + login, name="Use zshell")
        out("Please set a password for %s on %s" % (login, env.host_string))
        run("passwd " + login)
    return node


@task
def sshKey():
    """Install your SSH public key as an authorized key on the server"""
    key = util.getSSHKey()
    login = os.environ["USER"]
    authKeysPath = "~%s/.ssh/authorized_keys" % login
    scriptText = """KEYS=~%(login)s/.ssh/authorized_keys
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
        script(scriptText, "install ssh key to " + login)


@task
def servers():
    """Show configured target servers"""
    util.printJSON(getServerConf(SERVER_CONF_PATH))


@task
def fullBuild():
    """Create a new RackSpace VM and install Indivo X from scratch"""
    node = execute(provision)
    execute(email)
    execute(indivoServer)
    execute(indivoUIServer)

##### define a task for each serer in servers.json #####
for name, conf in getServerConf(SERVER_CONF_PATH).iteritems():
    instance = ServerTask(name)

env.config = SafeConfigParser({"installPrefix": "/web"})
env.config.read("conf/settings.conf")
