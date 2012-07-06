This is an automation library to build an [Indivo X](http://indivohealth.org/) install from scratch on a rackspace cloud server instance.

[Indivo X Installation Guide](http://wiki.chip.org/indivo/index.php/HOWTO:_install_Indivo_X#Database_Install)

#Prerequisites
* bourne-compatible shell
* python 2.6 or newer

#Dependencies

As long as the prerequisites listed above are already available on your system (any modern Linux or Mac computer will have them),
the code can automatically download and install the rest of its dependencies.

* node.js v0.6 and npm modules as listed in `package.json`

#Installation
* clone this repository to a Mac or Linux computer
* cd into the repository root directory
* ./do setup

#Configuration

* Edit conf.coffee and fill in your rackspace account name
* You do not need to put your API key into the conf file since it is secret. You will be securely prompeted for it when needed.

#Provisioning a new Indivo X server on Rackspace
* cd into the repository root directory
* Run the following "do" commands

  ./do development provision

* Copy the adminPass that gets printed out. You'll need it for the "users" task below. You can change it by ssh-ing in as root and running `passwd`.

  ./do development users

* You will see a warning about "The authenticity of host '...' can't be established.". Type "yes" to continue.
* When prompted, enter the root (admin) password
  ./do development sshKey
  ./do development packages
  ./do development easyInstall
  ./do development indivoDB
  ./do development indivoServer

* Note that `./do development provision` will create a new rackspace VM, which will have a new IP address. The new IP address will be updated in the `conf/servers.json` file, so you may want to add and commit that to git
* ssh into the server and manually run the DB reset

  ssh root@<server_IP>
  cd /web/indivo_server
  python utils/reset.py

* When prompted, type "yes"
* When prompted for a password, type the indivo DB password

  ./do development indivoUIServer
