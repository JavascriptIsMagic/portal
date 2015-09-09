module.exports = class Controller
  Action = class @Action
    constructor: (methods) ->
      @action = methods.reverse().reduce (next, method) ->
        -> yield method.apply @, next
    execute: (controller, next) ->
      yield @action.apply controller, next or ->
  @action = (methods...) ->
    new Action methods

  constructor: ({@url, @headers, @message}) ->
    unless @ instanceof Controller
      throw new Error "Controller contructor called without the 'new' operator."

  throw: (status, type, error) ->
    unless error instanceof Error
      error = new Error "@throw called without passing an instance of new Error: #{status}, #{type}, #{error}"
    error.type = type
    error.status = status
    @error = error
    throw error

  next: ->
    findPath = /\/[^\/]*/g
    pathname = ''
    while match = findPath.exec "#{url}"
      pathname += "#{match[0]}"
      if @[pathname] instanceof Controller
        controller = new @[pathname] { @url, @headers, @message }
        {@returns} = yield controller.execute url[pathname.length-1..], headers, body
        break
      if @[pathname] instanceof Action
        returns = yield @[pathname].execute @
        @returns = if returns? then returns else @returns
        break
    unless @returns is undefined
      @throw 404, 'not found', new Error '404: Controller Action not found or returned undefined.'
    @
