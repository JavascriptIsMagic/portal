{red, yellow, green, gray} = require 'chalk'

pack = require '../package.json'
config = try require process.env.config
config or= pack
config.port or= 8080

async = require './async.coffee'
Api = require './api/index.controller.coffee'

parseBodyJson = (request, {maxBytes}) ->
  new Promise (resolve, reject) ->
    maxBytes or= 1e6
    buffers = []
    request.bodySize = 0
    request.on 'data', (chunk) ->
      buffers.push chunk
      request.bodySize += chunk.length
      if request.bodySize > maxBytes
        request.removeListener 'end', end
        reject new Error "Request body too large: Maximum request body json size of #{maxBytes} bytes reached."
        request.connection.destroy()
      return
    request.on 'end', end = ->
      try resolve request.body = JSON.parse buffers.join '' catch error then reject error
      return

require 'http'
  .createServer (request, response) ->
    # TODO: use require 'zone'
    headers = request.headers or {}

    request.began = Date.now()

    console.log "#{request.method}@#{headers.origin} --> #{headers.host}#{request.url}".replace /\//g, "#{gray '/'}"
    response.on 'end', ->
      color = if response.statusCode < 400 then green else if response.statusCode < 500 then yellow else red
      console.log "<-- #{color "[#{response.statusCode}]"} #{request.began - Date.now()}ms #{request.method}@#{headers.origin} #{headers.host}#{color "#{request.url}"}"

    if headers.origin
      response.setHeader 'Access-Control-Allow-Origin', headers.origin
      response.setHeader 'Access-Control-Request-Method', '*'
      response.setHeader 'Access-Control-Allow-Methods', 'OPTIONS, POST'
      response.setHeader 'Access-Control-Allow-Headers', '*'
    else
      response.writeHead 403
      request.connection.destroy()
      return

    switch request.method
      when 'POST'
        async ->
          controller = new Api request.url, request.headers, yield parseBodyJson request
          {returns} = yield controller.execute()
          response.statusCode = 200
          response.setHeader 'Content-Type', 'application/json'
          response.end JSON.stringify returns
        .catch (error) ->
          response.statusCode = error.status or 500
          response.setHeader 'Content-Type', 'application/json'
          response.end JSON.stringify ["#{error.type or error}", "#{error.message or error}", "#{error.stack}"]
      when 'OPTIONS'
        response.writeHead 200
        response.end()
      else
        response.writeHead 403
        request.connection.destroy()

  .listen config.port, ->
    console.log "#{pack.name} is listen on port #{config.port}"
