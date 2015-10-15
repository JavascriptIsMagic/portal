require 'require-cson'
module.exports = (config) ->
  config = config or process.env.config
  if typeof config is 'string'
    config = require config
  config.sources ?= {}
  config.sources.project = path.resolve config.sources.project or config.dirname
  config.package ?= require "#{config.sources.project}/package.json"

  config.sources.build = path.resolve config.sources.build or "#{config.sources.project}/build"
  config.sources.public = path.resolve config.sources.public or "#{config.sources.build}/public"
  config
