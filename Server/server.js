var WebSocketServer               = require('ws').Server,
    webSocketServer               = new WebSocketServer({port: 5000, disableHixie: true}),
    webSocketConnections          = {},
    webSocketConnectionPrimaryKey = -1,
    apns                          = require('apn'),
    apnsConnection                = new apns.Connection({cert: 'apns/development_cer.pem', key: 'apns/development_p12.pem', gateway: 'gateway.sandbox.push.apple.com'}),
    // apnsConnection                = new apns.Connection({cert: 'apns/production_cer.pem', key: 'apns/production_p12.pem'}),
    deviceTokensConnected         = (),
    redisClient                   = require('redis').createClient(process.env.REDIS_PORT, process.env.REDIS_HOST);
    // mongodb = require('mongodb'),
    // mongo = new mongodb.Db(process.env.MONGO_NAME, new mongodb.Server(process.env.MONGO_HOST, process.env.MONGO_PORT, {}));


// $ redis-cli -h <host> -p <port> -a <pass>
redisClient.auth(process.env.REDIS_PASS, function (error) { if (error) throw error; });

// // $ mongo MONGO_HOST:MONGO_PORT/MONGO_NAME -u MONGO_USER -p MONGO_PASS
// mongo.open(function (error, dbP) {
//   if (error) throw error;
//   mongo.authenticate(process.env.MONGO_USER, process.env.MONGO_PASS, function (error, reply) { if (error) throw error; });
// });

// Redis Keys
//
// User:
//   Sign Up):
//     Get userID with deviceID:
//       - device:<deviceID> : <userID>
//     
//   Activate (Log In):
//     Set user.status to "1":
//       - user:<userID> : {"status": "1", "name": "Matt", "unread": "4"}
//
//   USERS_NEAREST_GET:
//     - Sorted set: users:<userID> : [[<userID>, <distance>], ... ]


// Constants
var MESSAGES_LIMIT = 50


// Message Type
var USER_SIGN_UP                = 0,
    // USER_LOG_IN                = 1,
    USERS_NEAREST_GET           = 2,
    MESSAGES_NEWEST_GET         = 3,
    DEVICE_TOKEN_SAVE_OR_UPDATE = 4,
    MESSAGE_TEXT_SEND           = 5,
    MESSAGE_TEXT_RECEIVE        = 6,
    // ERROR                       = 7;


// WebSocket Server
webSocketServer.on('connection', function (webSocketConnection) {

  // Add newly created webSocketConnection to webSocketConnections.
  var webSocketConnectionID = ++webSocketConnectionPrimaryKey;
  webSocketConnections[webSocketConnectionID] = webSocketConnection;
  var myDeviceToken = null;

  webSocketConnection.on('message', function (message) {

    console.log("message: " + message);

    // Functions
    var sendUsersNearest = function () {
      // TODO: Sort by nearest, limited to MESSAGES_LIMIT (sorted set).
      redisClient.sort('users', 'BY', 'nosort', 'HGETALL', 'user:*', function (error, usersNearest) {
        if (error) throw error;
        webSocketConnection.send('['+USERS_NEAREST_GET+','+JSON.stringify(usersNearest)+']');
      });
    }

    var sendMessagesNewest = function (messagesLengthOld) {
      redisClient.llen('messages', function (error, messagesLength) {
        if (error) throw error;
        var messagesLengthNew = messagesLength - messagesLengthOld;
        if (messagesLengthNew) {
          redisClient.lrange('messages', (messagesLengthNew > MESSAGES_LIMIT ? messagesLength-MESSAGES_LIMIT : messagesLengthOld), messagesLength-1, function (error2, messagesNewest) {
            if (error2) throw error2;
            if (messagesNewest) {
              webSocketConnection.send('['+MESSAGES_NEWEST_GET+','+messagesLength+','+JSON.stringify(newestMessages.map(JSON.parse))+"]");
            }
          });
        } else {
          webSocketConnection.send('['+MESSAGES_NEWEST_GET+'0,[]]');
        }
      });
    }

    var deviceTokenConnect = function (deviceToken) {
      deviceTokensConnected[deviceToken] = true;
    }

    var deviceTokenDisconnect = function (deviceToken) {
      delete deviceTokensConnected[deviceToken];
    }

    var deviceTokenAddThenConnect = function (deviceToken) {
      redisClient.sadd('deviceTokens', deviceToken, function (error, reply) {
        if (error) throw error;
        deviceTokenConnect(deviceToken);
      }
    }

    var deviceTokenRemoveAndAddThenDisconnectAndConnect = function (deviceTokenNew, deviceTokenOld) {
      // TODO: Use Reids transactions here.
      redisClient.srem('deviceTokens', deviceTokenOld, function (error, reply) {
        if (error) throw error;
        redisClient.sadd('deviceTokens', deviceTokenNew, function (error, reply) {
          if (error) throw error;
          deviceTokenDisconnect(deviceTokenOld);
          deviceTokenConnect(deviceTokenNew);
        });
      });    
    }

    var deviceTokenUpdate(deviceTokenNew, deviceTokenOld) {
      if (deviceTokenOld) {
        deviceTokenRemoveAndAddThenDisconnectAndConnect(deviceTokenNew, deviceTokenOld);
      } else {
        deviceTokenAddThenConnect(deviceTokenNew);
      }
    }

    var setUserOnlineThenDeviceTokenUpdate = function (userID, deviceTokenNew, deviceTokenOld) {
      redisClient.hset('user:'+userID, 'status', '1', function (error, reply) {
        if (error) throw error;
        if (deviceTokenNew) {
          deviceTokenUpdate(deviceTokenNew, deviceTokenOld);
        }
      });
    }


    // Message Handling
    var messageArray = JSON.parse(message); // TODO: Rescue and return error.
    switch (messageArray[0]) { // messageType

      case USER_SIGN_UP:
      // Client messages immediately after connecting to sign up (create) a new user.
      //
      // Client Message: [messageType,deviceID,deviceTokenNew,deviceTokenOld], e.g., [USER_SIGN_UP,"25EC4F70-3D...","c9a632...","473aba..."]
      // Server Reply:   [messageType,userID],                                 e.g., [USER_SIGN_UP,"1"]
      //
      // deviceID:    generated & stored by client
      // deviceToken: see DEVICE_TOKEN_SAVE_OR_UPDATE (optional)
      // userID:     generated by Redis (INCR "user").

      // TODO: Make this transactional.
      var deviceKey = 'device:'+messageArray[1] /* deviceID */;
      redisClient.get(deviceKey, function (error, userID) {
        if (error) throw error;
        if (userID) {
          webSocketConnection.send('['+USER_SIGN_UP+',"'+userID+'"]');
          setUserOnlineThenDeviceTokenUpdate(userID, messageArray[2] /* deviceTokenNew */, messageArray[3] /* deviceTokenOld */);
        } else {
          // Create new user.
          redisClient.incr('user', function (error, userID) {
            if (error) throw error;
            webSocketConnection.send('['+USER_SIGN_UP+',"'+userID+'"]');
            redisClient.sadd('users', userID, function (error, reply) {
              if (error) throw error;
              redisClient.set(deviceKey, userID, function (error, reply) {
                if (error) throw error;
                setUserOnlineThenDeviceTokenUpdate(userID, messageArray[2] /* deviceTokenNew */, messageArray[3] /* deviceTokenOld */);
              });
            });
          });
        }
      });

      // case USER_LOG_IN:
      // // Client messages immediately after connecting to log in (activate) an existing user.
      // //
      // // Client Message: [messageType,deviceID,deviceToken],   e.g., [USER_LOG_IN,"25EC4F70-3D...","c9a632..."]
      // //
      // // deviceToken:   see DEVICE_TOKEN_SAVE_OR_UPDATE (optional)
      // redisClient.get('device:'+messageArray[1] /* deviceID */, function (error, userID) {
      //   if (error) throw error;
      //   if (userID) {
      //     webSocketConnection.send('['+USER_SIGN_UP+',"'+userID+'"]');
      //     setUserOnlineThenDeviceTokenUpdate(userID, messageArray);
      //   } else {
      //     webSocketConnection.send('['+ERROR+',"Incorrect Device ID"]');
      //   }
      // });

      case USERS_NEAREST_GET:
      // Client messages, immediately after connecting, to get usersNearest.
      // Server replies with usersNearest, limited to MESSAGES_LIMIT.
      //
      // Client Message: [messageType],   e.g., [USERS_NEAREST_GET]
      // Server Reply:   [messageType,usersNearest], e.g., [USERS_NEAREST_GET,["c9a632...","473aba..."]]
      sendUsersNearest();
      break;

      case MESSAGES_NEWEST_GET:
      // TODO: Rm messagesLength from reply.

      // Client messages, immediately after connecting, to get messagesNewest.
      // Server replies with messagesNewest, limited to MESSAGES_LIMIT.
      //
      // Client Message: [messageType,messagesLengthOld],         e.g., [MESSAGES_NEWEST_GET,5]
      // Server Reply:   [messageType,messagesLength,messagesNewest], e.g., [MESSAGES_NEWEST_GET,7,[[978307200.0,"Hi"],[978307201.0,"Hey"]]]
      //
      // messagesLengthOld:  client's previously received messagesLength or 0, incremented every time client sends/receives a message
      // messagesLength: server's 'messages' list length
      // messagesNewest: array of sent_messages (See MESSAGE_TEXT_SEND)
      sendMessagesNewest(messageArray[1] /* messagesLengthOld */);
      break;

      case DEVICE_TOKEN_SAVE_OR_UPDATE:
      // Client sends this message to add its deviceTokenNew.
      //
      // Client Message: [messageType,deviceTokenNew,deviceTokenOld], e.g., [DEVICE_TOKEN_SAVE_OR_UPDATE,"c9a632...","473aba..."]
      //
      // deviceTokenNew: used with Apple Push Notification Service (APNs)
      // deviceTokenOld: to be removed (optional)
      deviceTokenUpdate(messageArray[1] /* deviceTokenNew */, messageArray[2] /* deviceTokenOld */);
      break;

      case MESSAGE_TEXT_SEND:
      // Client messages to send messageText.
      // Server replies with confirmation and message sent_timestamp.
      // Server broadcasts message to all other webSocketConnections.
      //
      // Client Message:   [messageType,messagesSendingKey,messageText],    e.g., [MESSAGE_TEXT_SEND,0,"Hi"]
      // Server Reply:     [messageType,messagesSendingKey,sent_timestamp], e.g., [MESSAGE_TEXT_SEND,0,978307200.0]
      // Server Broadcast: [messageType,sent_message],                      e.g., [MESSAGE_TEXT_RECEIVE,[978307200.0,"Hi"]]
      //
      // messagesSendingKey: key of message in client's _messagesSendingDictionary, which allows sending multiple messages simultaneously
      // sent_timestamp:     server's time interval, in seconds (double), since 1970 on receipt of message
      // sent_message:       [sent_timestamp,messageText]

      // Set sent_message to [sent_timestamp,messageText].
      var sent_timestamp = Date.now()/1000;
      var message_text = messageArray[2];
      var sent_message = JSON.stringify([sent_timestamp, message_text]);

      // Save sent_message to Redis.
      redisClient.rpush('messages', sent_message, function (error, reply) {
        if (error) throw error;

        // Send sent_timestamp back to client.
        webSocketConnection.send('['+MESSAGE_TEXT_SEND+','+messageArray[1] /* messagesSendingKey */ +','+sent_timestamp+']');

        // Broadcast message to other webSocketConnections.
        for (var webSocketConnectionKey in webSocketConnections) {
          if (webSocketConnectionKey !== webSocketConnectionID) {
            webSocketConnections[webSocketConnectionKey].send('['+MESSAGE_TEXT_RECEIVE+','+sent_message+']'); // TODO: Should we check for error?
          }
        }

        // Send push notifications to all device_tokens_disconnected.
        redisClient.sdiff('deviceTokens', 'deviceTokensConnected', function (error, device_tokens_disconnected) {
          if (error) throw error;
          if (device_tokens_disconnected.length) {
            var apns_notifcation = new apns.Notification();
            apns_notifcation.expiry = Math.floor(Date.now() / 1000) + 3600; // expires 1 hour from now
            apns_notifcation.badge = 9;
            apns_notifcation.sound = "MessageReceived.aiff";
            apns_notifcation.alert = message_text;

            for (var deviceToken in device_tokens_disconnected) {
                apns_notifcation.device = new apns.Device(deviceToken);
                apnsConnection.sendNotification(apns_notifcation);
            }
          }
        });
      });
      break;

      // case MESSAGE_TEXT_RECEIVE: // implemented by client
    }
  });

  webSocketConnection.on('close', function () {
    if (myDeviceToken) {
      redisClient.srem('deviceTokensConnected', myDeviceToken, function (error, reply) {
        if (error) throw error;
        delete webSocketConnections[webSocketConnectionID];
      });
    }
  });
});
