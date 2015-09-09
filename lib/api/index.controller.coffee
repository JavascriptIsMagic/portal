module.exports = class Api extends require '../controller.coffee'
  '/': @action ->
    "Ohya!"
