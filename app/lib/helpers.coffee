runInParallel = (promises, n, callback) ->
  results = []

  _runner = (data) ->
    return callback results if data.length is 0
    [current, tail] = [data[.. n - 1], data[n ..]]
    Q.all(current)
    .then (res) ->
      console.log "got response with length=#{res.length}"
      Array::push.apply results, res
      setTimeout () ->
        _runner tail
      , 100
    .catch (err) ->
      console.log 'got error, retrying...'
      setTimeout () ->
        _runner data
      , 3000
      # throw Error err

  _runner promises


splitIntoChunks = (arr, n) ->
  result = []
  for i in [0..arr.length] by n
    result.push arr[i..i+n-1]
  return result
  # _.groupBy arr, (el, index) -> Math.floor index / n

module.exports =
  runInParallel: runInParallel
  splitIntoChunks: splitIntoChunks
