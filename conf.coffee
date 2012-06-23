exports.appName = "M-CM Indivo"
exports.env =
  production: false
  staging: false
  test: false
  development: false

#http://wiki.chip.org/indivo/index.php/HOWTO:_install_Indivo_X#Pre-Requisites
packages = [
  "apache2-mpm-prefork"
  "postgresql"
  "python-django"
  "python-lxml"
  "python-psycopg2"
  "python-setuptools"
  "zsh"
]
exports.servers =
  staging:
    name: exports.appName + " Staging"
    #hostname: exports.appName.toLowerCase + "_staging"
    hostname: "108.166.59.92"
    imageName: /Ubuntu.*12\.04.*/i
    flavorName: "256 server"
    packages: packages
    easyInstall: ["South", "Markdown", "rdflib"]
    user: process.env.USER
exports.rackspace =
  auth:
    username: "focusaurus"
    apiKey: "thisisnottherealapikey"
