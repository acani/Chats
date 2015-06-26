var pg = require('pg'),
    webSocketServer = new (require('ws')).Server({port: (process.env.PORT || 5000)}),
    webSockets = {} // userID: webSocket

// CONNECT /:userID_sessionID
// wscat -c ws://localhost:5200/0123456789abcdef0123456789abcdef1
webSocketServer.on('connection', function (webSocket) {
  var userID_sessionID = webSocket.upgradeReq.url.substring(1).split('.')
  var userID = userID_sessionID[0]
  sessionID = userID_sessionID[1]

  console.log('userID_sessionID: ' + userID_sessionID)
  console.log('userID: ' + userID)
  console.log('sessionID: ' + sessionID)

  // Validate userID & sessionID
  if (/^\d+$/.test(userID) && /^[0-9a-f]{32}$/.test(sessionID)) { // valid
    pg.connect(process.env.DATABASE_URL, function(error, client, done) {
      client.query('SELECT sessions_get('+userID+')', function (error, result) {
        if (error || result.rows[0].id != sessionID) { // unauthorized
          webSocket.close()
        } else { // authorized
          webSocket.on('close', function () {
            delete webSockets[userID]
            console.log('deleted: ' + userID) // log
          })

          webSockets[userID] = webSocket
          console.log('authorized: ' + userID + ' in ' + Object.getOwnPropertyNames(webSockets)) // log

          // Forward Message
          //
          // Receive               Example
          // [toUserID, text]      [2, "Hello, World!"]
          //
          // Send                  Example
          // [fromUserID, text]    [1, "Hello, World!"]
          webSocket.on('message', function (message) {
            console.log('received from ' + userID + ': ' + message) // log
            var messageArray = JSON.parse(message)
            var toUserWebSocket = webSockets[messageArray[0]]
            if (toUserWebSocket) {
              console.log('sent to ' + messageArray[0] + ': ' + JSON.stringify(messageArray)) // log
              messageArray[0] = userID
              toUserWebSocket.send(JSON.stringify(messageArray))
            }
          })
        }
      })
    })
  } else { // invalid
    webSocket.close()
  }
})
