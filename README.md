#Indivo Provision

This is an automation library to build an [Indivo X](http://indivohealth.org/) install from scratch on a rackspace cloud server instance.

[Indivo X Installation Guide](http://wiki.chip.org/indivo/index.php/HOWTO:_install_Indivo_X#Database_Install)

#Prerequisites

* bourne-compatible shell
* python 2.6 or newer

#Dependencies

As long as the prerequisites listed above are already available on your system (any modern Linux or Mac computer will have them),
the code can automatically download and install the rest of its dependencies.

#Installation
* clone this repository to a Mac or Linux computer
* cd into the repository root directory

```
    ./do
```

* This will ensure a python virtualenv with pip, fabric, and our dependencies is available in `./python`

#How it works

This project is build upon:

* The [Fabric](http://fabfile.org) python library for task automation
* My [makitso](https://github.com/focusaurus/makitso) library with supporting modules for Fabric

Each command starts by running the `./do` wrapper script followed by a target server name and a task name. Run `./do` with no arguments to see the list of available tasks and server tasks.

#Provisioning a new Indivo X server on Rackspace

* cd into the repository root directory
* Run the following "do" commands

```
    ./do development fullBuild
```

* You will be prompted for your rackspace username and API key. This is available from the [rackspace cloud](https://manage.rackspacecloud.com) web site under "Your Account > API Access".
* You will be prompted to set a new root password for the server. Store this in a secure password system such as [LastPass](https://lastpass.com/) or [PassPack](http://passpack.com)
* Note that this will create a new rackspace VM, which will have a new IP address. The new IP address will be updated in the `conf/servers.json` file, so you may want to add and commit that to git
* fullBuild will also create a user account matching your current login, and you will be prompted to set a password for this account as well
* You will later be prompted for a sudo password. Use the password you just set for your personal unix account
* The `fullBuild` command is a soup-to-nuts that runs a series of smaller commands: provision, email, indivoServer, and indivoUIServer
* You will be prompted twice for the database password when the initial DB setup is being run.


* At this point the Indivo UI Server should be up and running, so put the server's IP address into your web browser (or for the main server use [https://portal.m-cm.net]())
* You should be able to register a new account and begin using the Indivo sample applications

#About Outgoing Email

*NOTE* emails are likely to be sent to your Spam folder initially since they are from a rackspace system, but they do seem to go out and make it all the way to gmail. Once you remove the "spam" label, all is well for receiving future emails from Indivo.
