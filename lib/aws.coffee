Aws = require 'aws-sdk'
{wrapCallback} = require './async.coffee'

module.exports = class AwsAsync extends Aws
  @aws = Aws
  for serviceName, service of Aws when service?.serviceIdentifier
    @[serviceName] = do (service) ->
      class AwsServiceAsync
        constructor: (options) ->
          @service = new service options
          for key, method of @service when typeof method is 'function'
            @[key] = wrapCallback (method.bind @service), args...
          @__proto__ = @service
