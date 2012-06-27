fs = require "fs"
exports.appName = "M-CM Indivo"
exports.env =
  production: false
  staging: false
  test: false
  development: false

exports.indivo =
  serverDistURL: "http://cloud.github.com/downloads/chb/indivo_server/indivo_server-v2.0.0.tar.gz"
  installPrefix: "/web"
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
serverJSON = fs.readFileSync("conf/servers.json")
exports.servers = JSON.parse serverJSON
for name, server of exports.servers
  server.packages = packages
  server.easyInstall = ["South", "Markdown", "rdflib"]
  server.imageName = /Ubuntu.*12\.04.*/i
  server.user = process.env.USER
exports.rackspace =
  auth:
    username: "focusaurus"
