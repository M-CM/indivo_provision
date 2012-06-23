_ = require "underscore"
async = require "async"
cloudservers = require "cloudservers"
commander = require "commander"
conf = require "../conf"
control = require "control"

out = console.log

provision = ->
  getCreds ->
    client = cloudservers.createClient conf.rackspace
    serverConf = conf.servers.staging
    async.parallel
      flavor: (callback) -> getFlavor(client, serverConf.flavorName, callback)
      image: (callback) -> getImage(client, serverConf.imageName, callback)
      (error, opt) ->
        return exit(error) if error
        opt.name = conf.servers.staging.name
        opt.client = client
        createServer opt, (server) ->
          #done

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

  opt.client.createServer options, (error, server) ->
   return callback(error) if error
   out server
   conf.servers.staging.address = server.addresses.public[0]
   out "Waiting for server to become active (2-5 min)"
   server.setWait {status: "ACTIVE"}, 5000, ->
      callback server

control.task "provision", "Create a new rackspace server", provision

module.exports = {getFlavor, getImage}
