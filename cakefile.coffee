module.exports = (projectDirectory = __dirname, buildDirectory = projectDirectory) ->
  {execSync} = require 'child_process'
  pkg = require "#{projectDirectory}/package.json"
  sources = do ->
    packageFile = "#{projectDirectory}/package.json"
    buildDirectory = "/srv/node_modules/#{pkg.name}"
    configFile = "/srv/#{pkg.name}.json"
    dist = "#{buildDirectory}/dist"
    build = "#{buildDirectory}/build"
    publicFiles = ("#{projectDirectory}/src/**/*.#{type}" for type in ['html', 'png', 'pdf', 'min.*'])
    clean = [
      "#{dist}/**/*"
      "#{build}/**/*"
    ]
    server = [
      "#{projectDirectory}/**/*"
      "!#{projectDirectory}/node_modules"
      "!#{projectDirectory}/node_modules/**"
      "!#{projectDirectory}/src"
      "!#{projectDirectory}/src/**"
      "!#{projectDirectory}/semantic"
      "!#{projectDirectory}/semantic/**"
      "!#{projectDirectory}/templates"
      "!#{projectDirectory}/templates/**"
    ]
    lessFiles = ["#{projectDirectory}/src/**/*.less", require.resolve "./src/style.less"]
    style = "#{dist}/style.min.css"
    bake = lessFiles.concat [
      "#{projectDirectory}/templates/**/*"
    ]
    bundle = "#{projectDirectory}/src/#{pkg.name}.bundle.cjsx"
    docs = "#{projectDirectory}/docs/"
    documented = [
      "#{projectDirectory}/**/*.coffee"
      "#{projectDirectory}/**/*.cjsx"
      "!#{projectDirectory}/node_modules/**"
    ]
    {
      buildDirectory
      config: configFile
      package: packageFile
      dist
      build
      public: publicFiles
      clean
      server
      less: lessFiles
      bake
      style
      bundle
      docs
      documented
    }
  fs = require 'fs'
  try
    semanticCSS = fs.readFileSync "#{projectDirectory}/semantic/dist/semantic.css"
    sources.public = sources.public.concat [
      "#{projectDirectory}/semantic/dist/**/semantic.*"
      "#{projectDirectory}/semantic/dist/**/icons.*"
    ]
  catch
    semanticCSS = fs.readFileSync require.resolve 'semantic-ui-css/semantic.css'

  {spawn} = require 'child_process'
  require 'cake-gulp'
  less = require 'gulp-less'
  concatCSS = require 'gulp-concat-css'
  minifyCSS = require 'gulp-minify-css'
  juice = require 'juice'

  streamify = require 'gulp-streamify'
  config = (require "srv/#{pkg.name}.json").AWS
  s3 = try (require 'gulp-s3-upload') config

  s3Options =
    Bucket: 'filecontent'
    ACL: 'public-read'
    ContentEncoding: 'gzip'
    keyTransform: (key) ->
      "static/#{pkg.cdn}/" + key.replace /\.gz$/, ''

  zlib = require 'zlib'
  gzip = require 'gulp-gzip'
  path = require 'path'

  grock = require 'grock'

  browserify = require 'browserify'
  watchify = require 'watchify'

  cjsx = require 'coffee-reactify'
  uglify = require 'uglifyify'

  option '-w', '--watch', 'Watchify files.'
  option '-d', '--deploy', 'Deploy files to production s3.'
  option '-u', '--update', 'Updates From package.json.'
  option '-docs', '--docs', 'Build Documentation.'



  ###
  BUILD
  ###
  task 'build:clean', 'Delete all auto-generated files.', (options, callback) ->
    del sources.clean, { force: yes }, (error, files) ->
      if error
        throw error
      log "[#{green 'Deleted'}]\n#{files.map(fancypath).join '\n'}"
      if options.update
        log "[#{green 'Updating'}] Node Modules..."
        del "#{sources.buildDirectory}/**", { force: yes }, (error, files) ->
          if error
            log "#{error}\n#{error.stack}"
            return callback()
          log "\n[#{green 'clean'}]\n", files.map(fancypath).join '\n '
          callback()
      else
        callback()

  task 'build', 'Browserify all the things!', ['build:clean'], (options, callback) ->
    #invoke 'build:version', options
    invoke 'build:public', options
    invoke 'build:less', options
    invoke 'build:launch', options
    if options.docs
      invoke 'docs', options
    if options.watch
      invoke 'build:logs', options
    config =
      entry: sources.bundle
      path: sources.dist
      debug: options.watch
    if options.watch
      for own key of watchify.args
        unless key of options
          config[key] = watchify.args[key]
    for own key of options
      config[key] = options[key]
    bundler = if options.watch then watchify (browserify config), poll: yes else browserify config

    bundler.transform [cjsx, extension: 'cjsx']
    unless options.watch
      bundler.transform [uglify, global: yes]
    bundler.require require.resolve(config.entry), entry: yes

    rebuild = (files) ->
      unless /package\.json/.test "#{files}"
        invoke 'build:version', options
      if Array.isArray files
        files = files
          .map fancypath
          .join '\n'
      log "[#{green if options.watch then 'Watchify!' else 'Browserify!'}]\n#{files or '...'}"
      stream = bundler
        .bundle()
        .on 'error', log.bind 'Browserify Error: '
        .pipe source config.entry
        .pipe rename 'bundle.min.js'
        .pipe dest config.path
      unless options.watch
        stream = stream
          .pipe debug title: "[#{green 'Gzip'}]"
          .pipe gzip append: yes, gzipOptions: level: zlib.Z_BEST_COMPRESSION
          .pipe dest sources.dist
        if options.deploy
          stream
            .pipe streamify s3 s3Options
    bundler
      .on 'update', rebuild
      .on 'log', log

    rebuild()

  ###
  LOGS INVOKE
  ###
  task 'build:logs', 'pm2 logs for server', (options, callback) ->
    log "[#{green 'pm2 logs'}]"
    spawn 'pm2', ["logs", "#{pkg.name}"], stdio: "inherit"
    callback()


  ###
  PUBLIC INVOKE
  ###

  task 're:public', 'Copies or uploads if --deploy static/public files again.', (options) ->
    stream = src sources.public
      .pipe changed sources.dist
      .pipe debug title: "[#{green 'Client'}]"
      .pipe dest sources.dist
    unless options.watch
      stream = stream
        .pipe debug title: "[#{green 'Gzip'}]"
        .pipe gzip append: yes, gzipOptions: level: zlib.Z_BEST_COMPRESSION
        .pipe dest sources.dist
      if options.deploy
        stream
          .pipe streamify s3 s3Options

  task 'build:public', 'Copies or uploads if --deploy static/public files.', ['re:public'], (options) ->
    if options.watch
      log "[#{green 'Watching'}] public files..."
      watch sources.public, { interval: 1777 }, ['re:public']

  ###
  BAKE INVOKE
  ###

  task 'build:less', 'Compiles Less Files.', (options, callback) ->
    stream = src sources.less
      .pipe changed sources.dist
      .pipe sourcemaps.init()
      .pipe less()
      .pipe concatCSS 'style.min.css'
      .pipe minifyCSS()
      .pipe sourcemaps.write 'style.css.map'
      .pipe dest sources.dist
      .pipe debug title: "[#{green 'Less'}]"
    unless options.watch
      stream = stream
        .pipe debug title: "[#{green 'Gzip'}]"
        .pipe gzip append: yes, gzipOptions: level: zlib.Z_BEST_COMPRESSION
        .pipe dest sources.dist
      if options.deploy
        stream = stream
          .pipe streamify s3 s3Options
    #callback()
    return stream


  # task 're:bake', 'Bakes Email And PDF Templates Again', ['build:less'], (options, callback) ->
  #   log "[#{green 'Baking'}] template files..."
  #   css = fs.readFileSync sources.style
  #   filename = "#{sources.build}/templates.coffee"
  #   try fs.mkdirSync sources.build
  #   fs.writeFileSync filename, "module.exports = \n"
  #   for templateFileName in fs.readdirSync "#{projectDirectory}/templates" when /\.cjsx$/.test templateFileName
  #     templateName = templateFileName.replace /\.cjsx$/, ''
  #     bakedTemplate = JSON.stringify juice.inlineContent("#{fs.readFileSync "#{projectDirectory}/templates/#{templateFileName}"}", "#{semanticCSS}#{css}")
  #     variables = {}
  #     bakedTemplate.replace /#{[^}]+}/g, (match) ->
  #       match.replace /\w+/g, (variable) ->
  #         variables[variable] = true
  #     fs.appendFileSync filename, "  #{JSON.stringify templateName}: ({#{ Object.keys(variables).join ',' }}) -> #{bakedTemplate}\n"
  #   log "[#{green 'Baking'}] Complete"
  #   callback()
  #
  # task 'build:bake', 'Bakes Email And PDF Templates', ['re:bake'], (options, callback) ->
  #   if options.watch
  #     log "[#{green 'Watching'}] *.less files..."
  #     watch sources.bake, { interval: 997 }, ['re:bake']
  #   callback()

  ###
  LAUNCH INVOKE
  ###

  launch = ->
    log "[#{green 'pm2 flush'}]"
    spawn 'pm2', ["flush"], stdio: "inherit"
    log "[#{green 'pm2 startOrRestart'}]"
    spawn 'pm2', ["startOrRestart", sources.config], stdio: "inherit"

  task 'build:serverfiles', 'Copies server files.', (options, callback) ->
    src sources.server
      .pipe changed sources.buildDirectory
      .pipe debug title: "[#{green 'Server'}]"
      .pipe dest sources.buildDirectory

  task 'build:update', 'Updates Node Modules --production if update flag', ['build:serverfiles'], (options, callback) ->
    install = (command) ->
      command = "npm install #{command}"
      log command
      execSync command, stdio: 'inherit', cwd: sources.buildDirectory
    if options.update
      install "-g node-pre-gyp@latest"
      dependencies = for own dependency of pkg.dependencies
        dependency
      install "-save --production #{dependencies.join '@latest '}@latest"
    callback()

  task 're:launch', 'restarts server', ['build:serverfiles'], (options, callback) ->
    launch()
    callback()

  task 'build:launch', 'restarts server', ['build:update'], (options, callback) ->
    launch()
    if options.watch
      log "[#{green 'Watching'}] server files..."
      watch (sources.server.concat ["!#{sources.package}"]), { interval: 2797 }, ['re:launch']
    callback()

  ###
  VERSION INVOKE
  ###

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

  ###
  DOCS INVOKE
  ###

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
