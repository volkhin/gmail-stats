{runInParallel, splitIntoChunks} = require 'lib/helpers'

class GapiHelper extends EventEmitter
  accessToken: null
  initialized: false
  scope: 'https://www.googleapis.com/auth/gmail.readonly'

  constructor: (@clientId) ->

  init: (callback) =>
    return callback() if @initialized
    console.log 'init'
    @onLoad () =>
      @checkAuth =>
        @initialized = true
        callback()

  onLoad: (callback) ->
    poll = ->
      return callback() if gapi?.client?
      window.setTimeout poll, 10
    poll()

  _doAuth: (immediate, callback) =>
    return callback @accessToken if @accessToken?
    authOptions =
      client_id: @clientId
      scope: @scope
      immediate: immediate
    gapi.auth.authorize authOptions, (authResult) =>
      @accessToken = authResult.access_token
      return callback? @accessToken

  checkAuth: (callback) =>
    @_doAuth true, callback

  auth: (callback) =>
    console.log 'auth'
    @_doAuth false, callback

  loadMessageIds: (callback) ->
    messages = []

    loadPart = (pageToken, callback) ->
      request = gapi.client.gmail.users.messages.list
        userId: 'me'
        pageToken: pageToken
        maxResults: 100
      request.execute (response) ->
        console.log response
        messages.push msg.id for msg in response.messages
        nextPage = response.nextPageToken
        if messages.length >= 500 then nextPage = null # FIXME: remove limits
        if nextPage?
          setTimeout () ->
            loadPart nextPage, callback
          , 100
        else
          callback()

    loadPart null, ->
      console.log messages.length
      callback(messages)

  loadMessages: (callback) =>
    console.log 'loading messages...'
    messages = []

    getMessage = (id) ->
      gapi.client.gmail.users.messages.get
        userId: 'me'
        id: id

    getBatchPromise = (ids) =>
      Q.promise (resolve, reject, notify) =>
        batch = gapi.client.newRpcBatch()
        _(ids).each (id) -> batch.add getMessage(id)
        batch.execute (response) =>
          chunk = _.map response, (obj) -> obj.result
          # messages.push obj.result for id, obj of response
          Array::push.apply messages, chunk
          @emit 'messages:part', chunk
          resolve()

    gapi.client.load 'gmail', 'v1', =>
      @loadMessageIds (messageIds) ->
        chunks = splitIntoChunks messageIds, 100
        result = chunks.reduce (result, chunk) ->
          result.then () -> getBatchPromise chunk
        , Q []
        result.then(() -> callback messages).done()

module.exports = GapiHelper
