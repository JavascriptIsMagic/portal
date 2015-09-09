module.exports =
async = (generator) -> new Promise (resolve, reject) ->
  if typeof generator is 'function'
    generator = generator()
  unless typeof generator?.next is 'function'
    return resolve generator
  resolved = (value) ->
    try result = generator.next value
    catch error then return reject error
    returned result
  rejected = (error) ->
    try result = generator.throw error
    catch error then return reject error
    returned result
  returned = (result) ->
    if result.done then return resolve result.value
    promise = result.value
    if (not promise) and (typeof result?.then is 'function') and typeof result?.catch is 'function'
      promise = result
    if typeof promise?.next is 'function'
      promise = async promise
    if Array.isArray promise
      promise = async.array promise
    else if promise.constructor is Object
      promise = async.object promise
    if (typeof promise?.then is 'function') and typeof promise?.catch is 'function'
      promise
        .then resolved
        .catch rejected
    else
      rejected new Error "Only promises/generators or arrays/objects of promises/generators can be yielded."
  resolved()
async.async = async

async.array = (array) ->
  new Promise (resolve, reject) ->
    pending = array.length
    results = new Array pending
    array.forEach (promise, index) ->
      if typeof promise?.next is 'function'
        promise = async promise
      promise
        .catch reject
        .then (value) ->
          pending -= 1
          results[index] = value
          if pending is 0
            resolve results

async.object = (object) ->
  new Promise (resolve, reject) ->
    keys = Object.keys object
    pending = keys.length
    results = {}
    keys.forEach (key) ->
      promise = object[key]
      if typeof promise?.next is 'function'
        promise = async promise
      promise
        .catch reject
        .then (value) ->
          pending -= 1
          results[key] = value
          if pending is 0
            resolve results

async.callback = (method, args...) ->
  context = @
  new Promise (resolve, reject) ->
    args.push (error, value) ->
      if error then reject error else resolve value
    method.apply context, args

async.wrapCallback = (method) -> (args...) ->
  context = @
  new Promise (resolve, reject) ->
    args.push (error, value) ->
      if error then reject error else resolve value
    method.apply context, args

async.wrapClass = (Class) ->
  class AsyncClass extends Class
    for name, method of Class:: when typeof method is 'function'
      @::[name] = async.wrapCallback method
