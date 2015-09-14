module.exports = class Component extends React.Component
  class @State extends Bacon.Bus
    constructor: (state) ->
      unless @ instanceof State
        return new Component.State state
      Bacon.Bus.apply @
      property = @toProperty state ?= null
      for prototype in [Bacon.Observable::, Bacon.Property::]
        for key, value of prototype when value instanceof Function and key isnt 'constructor'
          @[key] = value.bind property
    getValue: ->
      @property.current?.value?()

  constructor: ->
    React.createClass.apply @, arguments

Bacon.Property::toState = ->
  value = @current?.value?()
  state = new Component.State value
  state.plug @
  state
