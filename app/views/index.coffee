GapiHelper = require 'lib/gapi'

CLIENT_ID = 'PUT YOU CLIENT ID HERE'

colors = ["#FF3030","#FF8800","#00B6F7","#95D900","#FFEA00","#BB7BF1","#0080FF","#FF8888","#87888E","#457F51","#B5B6BE"]

module.exports = class IndexView extends Backbone.View
  messages: []
  senders: {}
  chart: null
  pieChart: null

  plotGraph: () =>
    sendersList = _.map @senders, (count, sender) ->
      sender: sender
      count: count
    sendersList = (_.sortBy sendersList, (item) -> item.count).reverse()
    data = []
    _(sendersList[..19]).each (item, index) ->
      console.log "#{item.sender} -- #{item.count}"
      hue = 360 * Math.random()
      color = colors[index % colors.length]
      highlight = color
      data.push
        value: item.count
        color: color
        highlight: highlight
        label: item.sender
    $('#chart').show()
    @pieChart?.destroy()
    @pieChart = @chart.Pie data, animation: false

  extractFrom: (msg) ->
    fromHeader = _(msg.payload.headers).find (header) -> header.name is 'From'
    from = fromHeader?.value
    return from.match(/<(.+)>/)?[1] or from

  processData: (messages) =>
    _.each messages, (msg) =>
      from = @extractFrom msg
      @senders[from] = @senders[from] + 1 or 1

    $('#resultTable').show()
    _.each messages, (msg) ->
      row = $('<tr/>')
      row.append $('<td/>').text ''
      row.append $('<td/>').text msg.snippet
      $('#resultTable > tbody').append row

  initialize: ->
    $('#chart').hide()
    $('#resultTable').hide()
    $('.alert').hide()

    gapiHelper = new GapiHelper CLIENT_ID
    gapiHelper.init ->

    $('#authButton').click ->
      gapiHelper.init ->
        gapiHelper.auth ->

    @chart = new Chart $('#chart').get(0).getContext('2d')

    $('#loadButton').click =>
      if not gapiHelper.accessToken?
        console.log 'You have to be authorized'
        return
      gapiHelper.on 'messages:part', (messages) =>
        console.log "#{messages.length} messages loaded", messages
        @processData messages
        console.log @senders
        @plotGraph()
      gapiHelper.loadMessages (messages) ->
        alert = $('.alert')
        alert.removeClass().addClass('alert alert-success')
        alert.find('#alert-message').text 'All messages have been loaded!'
        alert.slideDown(500).delay(5000).slideUp(500)
