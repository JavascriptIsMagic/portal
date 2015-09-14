module.exports = (url, body) ->
  request = new XMLHttpRequest
  request.url = url
  request.body = body
  promise = new Promise (resolve, reject) ->
    request.onload = (event) ->
      event.request = request
      promise.status = 'complete'
      try
        data = JSON.parse request.responseText
        if event.status < 400
          event.status = 'complete'
          event.data = data
          resolve event
        else
          event.status = 'error'
          event.error = data.error or new Error 'Request status not okay.'
          reject event
      catch error
        event.status = 'error'
        reject event
  promise.request = request
  promise.status = 'pending'
  request.open 'POST', "#{url}"
#  request.setRequestHeader 'Content-Type', 'application/json;charset=UTF-8'
  request.send JSON.stringify body
  promise
