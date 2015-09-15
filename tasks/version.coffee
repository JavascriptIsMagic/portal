fs = require 'fs'

module.exports = (sources) ->
  task 'build:version', 'Incriments version number every incramental build', (options, callback) ->
    type = if options.deploy then 1 else 2
    fs.readFile sources.package, (error, packageJson) ->
      throw error if error
      pkg = JSON.parse packageJson
      oldVersion = pkg.version
      pkg.version or= "0.0.0"
      version = pkg.version.split '.'
      version[type] = (version[type]|0) + 1
      pkg.version = version.join '.'
      fs.writeFileSync sources.package, JSON.stringify pkg, null, 2
      log "[#{magenta 'Version'}] #{pkg.name} v#{oldVersion} -> #{green "v#{pkg.version}"}"
      callback()
