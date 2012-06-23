This is an automation library to build an [Indivo X](http://indivohealth.org/) install from scratch on a rackspace cloud server instance.

[Indivo X Installation Guide](http://wiki.chip.org/indivo/index.php/HOWTO:_install_Indivo_X#Database_Install)

#Dependencies
* Node.js version 0.6

#Installation
* cd into the repository root directory
* ./node/bin/npm install

#Usage
./makitso.coffee staging provision
./makitso.coffee staging user
./makitso.coffee staging packages
./makitso.coffee staging easyInstall
./makitso.coffee staging indivoDB
