{spawn} = require 'child_process'

module.exports = (sources) ->
  task 'build:logs', 'pm2 logs for server', (options, callback) ->
    log "[#{green 'pm2 logs'}]"
    spawn 'pm2', ["logs", "#{pkg.name}"], stdio: "inherit"
    callback()
