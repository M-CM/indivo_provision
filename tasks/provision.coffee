#Provisions a new rackspace virtual machine instance
#Takes settings from the server configuration for name, flavorName, and imageName

_ = require "underscore"
async = require "async"
cloudservers = require "cloudservers"
commander = require "commander"
conf = require "../conf"
control = require "control"
events = require "events"
fs = require "fs"
path = require "path"

out = console.log
confPath =  path.join(__dirname, "..", "conf", "servers.json")

provision = (server) ->
  getCreds ->
    client = cloudservers.createClient conf.rackspace
    async.parallel
      flavor: async.apply getFlavor, client, server.flavorName
      image: async.apply getImage, client, server.imageName
      (error, opt) ->
        return exit(error) if error
        opt.name = server.name
        opt.client = client
        createServer opt, (cloudServer) ->
          out "Server build complete"
          out "Name: #{cloudServer.name}"
          out "IP: #{cloudServer.addresses.public[0]}"
          out "adminPass: #{cloudServer.adminPass}"
          readConfig server, (error, config) ->
            return exit(error) if error
            config[server.configName].address = cloudServer.addresses.public[0]
            writeConfig config, (error) ->
              return exit(error) if error
              module.exports.emit "done", server

readConfig = (server, callback) ->
  fs.readFile confPath, (error, json) ->
    callback error, JSON.parse json

writeConfig = (config, callback) ->
  fs.writeFile confPath, JSON.stringify(config, null, 2), callback

exit = (error) ->
  process.stderr.write(error + "\n")
  process.exit(2)

getCreds = (callback)->
  ask = ->
    commander.password 'Rackspace API Key: ', (key) ->
      if not /^[a-f0-9]{32}$/i.test key
        out "Invalid key. Should be a 32-char hexadecimal string. <CTRL>+c to abort."
        return ask()
      conf.rackspace.auth.apiKey = key
      callback key
  ask()

getFlavor = (client, flavorName, callback) ->
  client.getFlavors (error, flavors) ->
    return callback(error) if error
    flavor = _.find flavors, (flavor) -> flavorName == flavor.name
    delete flavor.client if flavor
    callback null, flavor

getImage = (client, imageName, callback) ->
  client.getImages (error, images) ->
    return callback(error) if error
    image = _.find images, (image) ->
      if typeof imageName == "string"
        return imageName == image.name
      else
        #Handle Regular Expression
        return imageName.test image.name
    delete image.client if image
    callback null, image

createServer = (opt, callback) ->
  #TODO handle missing flavor or error here
  options =
    name: opt.name
    image: opt.image.id
    flavor: opt.flavor.id

  opt.client.createServer options, (error, cloudServer) ->
   return callback(error) if error
   out "Waiting for server to become active (5-10 min)"
   cloudServer.setWait {status: "ACTIVE"}, 5000, ->
      callback cloudServer

control.task "provision", "Create a new rackspace server", provision

module.exports = {getFlavor, getImage}
_.extend module.exports, events.EventEmitter.prototype
