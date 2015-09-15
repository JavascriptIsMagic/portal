del = require 'del'
grock = require 'grock'

module.exports = (sources) ->
  task 'docs:clean', 'Cleans the documentation directory.', (options, callback) ->
    del "#{sources.docs}**/*", { force: yes }, (error, files) ->
      if error
        log "#{error}\n#{error.stack}"
        return callback()
      log "\n[#{green 'clean'}]\n", files.map(fancypath).join '\n '
      callback()

  task 'build:docs', 'Generates the documentation using Grock', ['docs:clean'], (options, callback) ->
    grock.generator
      glob: sources.documented
      out: sources.docs
      style: 'solarized'
    callback()

  task 'docs', 'Generates the documentation using Grock', ['build:docs'], (options, callback) ->
    if options.watch
      watch sources.documented, ['build:docs']
    callback()
