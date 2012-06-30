#Provisions a new rackspace virtual machine instance
#Takes settings from the server configuration for name, flavorName, and imageName

_ = require "underscore"
async = require "async"
cloudservers = require "cloudservers"
commander = require "commander"
conf = require "../conf"
control = require "control"
events = require "events"

out = console.log

provision = (server) ->
  getCreds ->
    client = cloudservers.createClient conf.rackspace
    async.parallel
      flavor: (callback) -> getFlavor(client, server.flavorName, callback)
      image: (callback) -> getImage(client, server.imageName, callback)
      (error, opt) ->
        return exit(error) if error
        opt.name = server.name
        opt.client = client
        console.dir conf.servers[server.configName]
        createServer opt, (cloudServer) ->
          out "Server build complete"
          out "Name: #{cloudServer.name}"
          out "IP: #{cloudServer.addresses.public[0]}"
          out "adminPass: #{cloudServer.adminPass}"
          #TODO store updated IP in server conf
          newJSONConfig = _.pick(
            conf.servers[server.configName], ["name", "flavorName"])
          newJSONConfig.address = server.addresses.public[0]
          json = JSON.stringify newJSONConfig
          fs.writeFile "../conf/servers.json", json, (error) ->
            throw error if error
            module.exports.emit "done", server

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
   out "Waiting for server to become active (4-10 min)"
   cloudServer.setWait {status: "ACTIVE"}, 5000, ->
      callback cloudServer

control.task "provision", "Create a new rackspace server", provision

module.exports = {getFlavor, getImage}
_.extend module.exports, events.EventEmitter.prototype
