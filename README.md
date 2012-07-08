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

```
    ./do setup
```

#Configuration

* Edit conf.coffee and fill in your rackspace account name

#Provisioning a new Indivo X server on Rackspace
* cd into the repository root directory
* Run the following "do" commands

```
    ./do development provision
```

* You will be prompted for your rackspace API key. This is available from the [rackspace cloud](https://manage.rackspacecloud.com) web site under "Your Account > API Access".
* Copy the adminPass that gets printed out. You'll need it for the "users" task below. You can change it by ssh-ing in as root and running `passwd`.
* Note that this will create a new rackspace VM, which will have a new IP address. The new IP address will be updated in the `conf/servers.json` file, so you may want to add and commit that to git

```
    ./do development users
```

* You will see a warning about "The authenticity of host '...' can't be established.". Type "yes" to continue.
* When prompted, enter the root (admin) password. You will see this once per user and once at the end when sudo is configured.

```
    ./do development sshKey
```

* This will create a unix account on the remote server with the same login as your current login on your development computer
* You will be prompted for the root password again
* To use an alternate login or ssh key path, provide them on the command line
  * ./do development sshKey mylogin ~/mykey
* Normal user accounts don't allow password login as configured here, only ssh key. If you want password login, ssh in (using your sshkey) and run `passwd`.

```
./do development packages
./do development easyInstall
./do development email
./do development indivoDB
./do development indivoServer
```

* ssh into the server and manually run the DB reset

```
    ssh root@<server_IP>
    python /web/indivo_server/utils/reset.py
    exit
```

* When prompted, type "yes"
* When prompted for a password, type the indivo DB password

```
    ./do development indivoUIServer
```

* At this point the Indivo UI Server should be up and running, so put the server's IP address into your web browser
* You should be able to register a new account and begin using the Indivo sample applications
