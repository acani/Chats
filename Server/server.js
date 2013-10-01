var WebSocketServer               = require('ws').Server,
    webSocketServer               = new WebSocketServer({port: 5000, disableHixie: true}),
    webSocketConnections          = {},
    webSocketConnectionPrimaryKey = -1,
    apns                          = require('apn'),
    apnsConnection                = new apns.Connection({cert: 'apns/development_cer.pem', key: 'apns/development_p12.pem', gateway: 'gateway.sandbox.push.apple.com'}),
    // apnsConnection                = new apns.Connection({cert: 'apns/production_cer.pem', key: 'apns/production_p12.pem'}),
    deviceTokensConnected         = {},
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
//   MESSAGE_TYPE_USERS_NEAREST_GET:
//     - Sorted set: users:<userID> : [[<userID>, <distance>], ... ]


// Constants
var MESSAGES_LIMIT = 50

var MESSAGE_TYPE_USER_SIGN_UP         = 0,
    // MESSAGE_TYPE_USER_LOG_IN         = 1,
    MESSAGE_TYPE_USERS_NEAREST_GET    = 2,
    MESSAGE_TYPE_MESSAGES_NEWEST_GET  = 3,
    MESSAGE_TYPE_DEVICE_TOKEN_UPDATE  = 4,
    MESSAGE_TYPE_MESSAGE_TEXT_SEND    = 5,
    MESSAGE_TYPE_MESSAGE_TEXT_RECEIVE = 6;
    // MESSAGE_TYPE_ERROR             = 7;

var USER_STATUS_OFFLINE         = '0',
    USER_STATUS_ONLINE          = '1';


var checkError = function(error, msg) {
    if (error) {
	console.log("ERROR:" + msg + ":" + error);
	throw error;
    }
}

var deviceTokenDisconnect = function (deviceToken) {
    delete deviceTokensConnected[deviceToken];
}

// WebSocket Server
webSocketServer.on('connection', function (webSocketConnection) {

  // Add newly created webSocketConnection to webSocketConnections.
  var webSocketConnectionID = ++webSocketConnectionPrimaryKey;
  webSocketConnections[webSocketConnectionID] = webSocketConnection;
  var myDeviceToken = null;

  webSocketConnection.on('message', function (message) {

    console.log("incoming message: " + message);

    // Functions
    var sendUsersNearest = function () {
      // TODO: Sort by nearest, limited to MESSAGES_LIMIT (sorted set).
	redisClient.smembers('users', function(error, usersNearest) {
	checkError(error, "sendUsersNearest:");
        webSocketConnection.send('['+MESSAGE_TYPE_USERS_NEAREST_GET+','+JSON.stringify(usersNearest)+']');
      });
    }

    var sendMessagesNewest = function (messagesLengthOld) {
      redisClient.llen('messages', function (error, messagesLength) {
	checkError(error, "sendMessagesNewest1");
        var messagesLengthNew = messagesLength - messagesLengthOld;
        if (messagesLengthNew) {
          redisClient.lrange('messages', (messagesLengthNew > MESSAGES_LIMIT ? messagesLength-MESSAGES_LIMIT : messagesLengthOld), messagesLength-1, function (error2, messagesNewest) {
	  checkError(error2, "sendMessagesNewest2");
            if (messagesNewest) {
              webSocketConnection.send('['+MESSAGE_TYPE_MESSAGES_NEWEST_GET+','+messagesLength+','+JSON.stringify(newestMessages.map(JSON.parse))+"]");
            }
          });
        } else {
          webSocketConnection.send('['+MESSAGE_TYPE_MESSAGES_NEWEST_GET+'0,[]]');
        }
      });
    }

    var deviceTokenConnect = function (deviceToken) {
      myDeviceToken = deviceToken;
      deviceTokensConnected[deviceToken] = true;
    }


    var deviceTokenAddThenConnect = function (deviceToken) {
      redisClient.sadd('deviceTokens', deviceToken, function (error, reply) {
	checkError(error, "deviceTokenAddThenConnect");
        deviceTokenConnect(deviceToken);
      });
    }

    var deviceTokenRemoveAndAddThenDisconnectAndConnect = function (deviceTokenNew, deviceTokenOld) {
      // TODO: Use Reids transactions here.
      redisClient.srem('deviceTokens', deviceTokenOld, function (error, reply) {
      checkError(error, "deviceTokenRemoveAndAddThenDisconnectAndConnect:srem");
        redisClient.sadd('deviceTokens', deviceTokenNew, function (error, reply) {
      checkError(error, "deviceTokenRemoveAndAddThenDisconnectAndConnect:sadd");
          deviceTokenDisconnect(deviceTokenOld);
          deviceTokenConnect(deviceTokenNew);
        });
      });    
    }

    var deviceTokenUpdate = function (deviceTokenNew, deviceTokenOld) {
      if (deviceTokenOld) {
        deviceTokenRemoveAndAddThenDisconnectAndConnect(deviceTokenNew, deviceTokenOld);
      } else {
        deviceTokenAddThenConnect(deviceTokenNew);
      }
    }

    var setUserOnlineThenDeviceTokenUpdate = function (userID, deviceTokenNew, deviceTokenOld) {
      redisClient.hset('user:'+userID, 'status', USER_STATUS_ONLINE, function (error, reply) {
	      checkError(error, "setUserOnlineThenDeviceTokenUpdate");
        if (deviceTokenNew) {
          deviceTokenUpdate(deviceTokenNew, deviceTokenOld);
        }
      });
    }


    // Message Handling
    var messageArray = JSON.parse(message); // TODO: Rescue and return error.
    switch (messageArray[0]) { // messageType

      case MESSAGE_TYPE_USER_SIGN_UP:
      // Client messages immediately after connecting to sign up (create) a new user.
      //
      // Client Message: [messageType,deviceID,deviceTokenNew,deviceTokenOld], e.g., [MESSAGE_TYPE_USER_SIGN_UP,"25EC4F70-3D...","c9a632...","473aba..."]
      // Server Reply:   [messageType,userID],                                 e.g., [MESSAGE_TYPE_USER_SIGN_UP,"1"]
      //
      // deviceID:    generated & stored by client
      // deviceToken: see MESSAGE_TYPE_DEVICE_TOKEN_UPDATE (optional)
      // userID:     generated by Redis (INCR "user").

      // TODO: Make this transactional.
      console.log("MESSAGE_TYPE_USER_SIGN_UP");
      var deviceKey = 'device:'+messageArray[1] /* deviceID */;
      redisClient.get(deviceKey, function (error, userID) {
	 checkError(error, "MESSAGE_TYPE_USER_SIGN_UP");
        if (userID) {
	  console.log("MESSAGE_TYPE_USER_SIGN_UP - Existing user..");

          setUserOnlineThenDeviceTokenUpdate(userID, messageArray[2] /* deviceTokenNew */, messageArray[3] /* deviceTokenOld */);

          webSocketConnection.send('['+MESSAGE_TYPE_USER_SIGN_UP+',"'+userID+'"]');
        } else {
	  console.log("MESSAGE_TYPE_USER_SIGN_UP - New user..");

          // Create new user.
          // TODO: Consider: HMSET device:<deviceID> user <userID> token <deviceToken>
          redisClient.incr('user', function (error, userID) {
		  checkError(error, "MESSAGE_TYPE_USER_SIGN_UP2");
            redisClient.sadd('users', userID, function (error, reply) {
		    checkError(error, "MESSAGE_TYPE_USER_SIGN_UP3");
              redisClient.set(deviceKey, userID, function (error, reply) {
		      checkError(error, "MESSAGE_TYPE_USER_SIGN_UP4");
                setUserOnlineThenDeviceTokenUpdate(userID, messageArray[2] /* deviceTokenNew */, messageArray[3] /* deviceTokenOld */);
              });
            });
	      });

            webSocketConnection.send('['+MESSAGE_TYPE_USER_SIGN_UP+',"'+userID+'"]');

        }
      });

      // case MESSAGE_TYPE_USER_LOG_IN:
      // // Client messages immediately after connecting to log in (activate) an existing user.
      // //
      // // Client Message: [messageType,deviceID,deviceToken],   e.g., [MESSAGE_TYPE_USER_LOG_IN,"25EC4F70-3D...","c9a632..."]
      // //
      // // deviceToken:   see MESSAGE_TYPE_DEVICE_TOKEN_UPDATE (optional)
      // redisClient.get('device:'+messageArray[1] /* deviceID */, function (error, userID) {
      //   checkError(error);
      //   if (userID) {
      //     webSocketConnection.send('['+MESSAGE_TYPE_USER_SIGN_UP+',"'+userID+'"]');
      //     setUserOnlineThenDeviceTokenUpdate(userID, messageArray);
      //   } else {
      //     webSocketConnection.send('['+ERROR+',"Incorrect Device ID"]');
      //   }
      // });

      case MESSAGE_TYPE_USERS_NEAREST_GET:
	  console.log("MESSAGE_TYPE_USERS_NEAREST_GET");

      // Client messages, immediately after connecting, to get usersNearest.
      // Server replies with usersNearest, limited to MESSAGES_LIMIT.
      //
      // Client Message: [messageType],   e.g., [MESSAGE_TYPE_USERS_NEAREST_GET]
      // Server Reply:   [messageType,usersNearest], e.g., [MESSAGE_TYPE_USERS_NEAREST_GET,["c9a632...","473aba..."]]
      sendUsersNearest();
      break;

      case MESSAGE_TYPE_MESSAGES_NEWEST_GET:
	  console.log("MESSAGE_TYPE_MESSAGES_NEWEST_GET");

      // TODO: Rm messagesLength from reply.

      // Client messages, immediately after connecting, to get messagesNewest.
      // Server replies with messagesNewest, limited to MESSAGES_LIMIT.
      //
      // Client Message: [messageType,messagesLengthOld],         e.g., [MESSAGE_TYPE_MESSAGES_NEWEST_GET,5]
      // Server Reply:   [messageType,messagesLength,messagesNewest], e.g., [MESSAGE_TYPE_MESSAGES_NEWEST_GET,7,[[978307200.0,"Hi"],[978307201.0,"Hey"]]]
      //
      // messagesLengthOld:  client's previously received messagesLength or 0, incremented every time client sends/receives a message
      // messagesLength: server's 'messages' list length
      // messagesNewest: array of sentMessages (See MESSAGE_TYPE_MESSAGE_TEXT_SEND)
      sendMessagesNewest(messageArray[1] /* messagesLengthOld */);
      break;

      case MESSAGE_TYPE_DEVICE_TOKEN_UPDATE:
	  console.log("MESSAGE_TYPE_DEVICE_TOKEN_UPDATE");

      // Client sends this message to add its deviceTokenNew.
      //
      // Client Message: [messageType,deviceTokenNew,deviceTokenOld], e.g., [MESSAGE_TYPE_DEVICE_TOKEN_UPDATE,"c9a632...","473aba..."]
      //
      // deviceTokenNew: used with Apple Push Notification Service (APNs)
      // deviceTokenOld: to be removed (optional)
      deviceTokenUpdate(messageArray[1] /* deviceTokenNew */, messageArray[2] /* deviceTokenOld */);
      break;

      case MESSAGE_TYPE_MESSAGE_TEXT_SEND:
	  console.log("MESSAGE_TYPE_MESSAGE_TEXT_SEND");

      // Client messages to send messageText.
      // Server replies with confirmation and message sentTimestamp.
      // Server broadcasts message to all other webSocketConnections.
      //
      // Client Message:   [messageType,messagesSendingKey,messageText],    e.g., [MESSAGE_TYPE_MESSAGE_TEXT_SEND,0,"Hi"]
      // Server Reply:     [messageType,messagesSendingKey,sentTimestamp], e.g., [MESSAGE_TYPE_MESSAGE_TEXT_SEND,0,978307200.0]
      // Server Broadcast: [messageType,sentMessage],                      e.g., [MESSAGE_TYPE_MESSAGE_TEXT_RECEIVE,[978307200.0,"Hi"]]
      //
      // messagesSendingKey: key of message in client's _messagesSendingDictionary, which allows sending multiple messages simultaneously
      // sentTimestamp:     server's time interval, in seconds (double), since 1970 on receipt of message
      // sentMessage:       [sentTimestamp,messageText]

      // Set sentMessage to [sentTimestamp,messageText].
      var sentTimestamp = Date.now()/1000;
      var message_text = messageArray[2];
      var sentMessage = JSON.stringify([sentTimestamp, message_text]);

      // Save sentMessage to Redis.
      redisClient.rpush('messages', sentMessage, function (error, reply) {
	      checkError(error, "TEXT_SEND");

        // Send sentTimestamp back to client.
        webSocketConnection.send('['+MESSAGE_TYPE_MESSAGE_TEXT_SEND+','+messageArray[1] /* messagesSendingKey */ +','+sentTimestamp+']');

        // Broadcast message to other webSocketConnections.
        for (var webSocketConnectionKey in webSocketConnections) {
          if (webSocketConnectionKey !== webSocketConnectionID) {
            webSocketConnections[webSocketConnectionKey].send('['+MESSAGE_TYPE_MESSAGE_TEXT_RECEIVE+','+sentMessage+']'); // TODO: Should we check for error?
          }
        }

        // Send push notifications to all disconnected devices.
        redisClient.smembers('deviceTokens', function (error, deviceTokens) {
		checkError(error, "TEXT_SEND:deviceTokens");
          if (deviceTokens.length) {
            var apns_notifcation = new apns.Notification();
            apns_notifcation.expiry = Math.floor(Date.now() / 1000) + 3600; // expires 1 hour from now
            apns_notifcation.badge = 9;
            apns_notifcation.sound = "MessageReceived.aiff";
            apns_notifcation.alert = message_text;

            for (var deviceToken in deviceTokens) {
              if (deviceTokensConnected[deviceToken]) continue;
              apns_notifcation.device = new apns.Device(deviceToken);
              apnsConnection.sendNotification(apns_notifcation);
            }
          }
        });
      });
      break;

      // case MESSAGE_TYPE_MESSAGE_TEXT_RECEIVE: // implemented by client
    }
  });

  webSocketConnection.on('close', function () {
    deviceTokenDisconnect(myDeviceToken);
    delete webSocketConnections[webSocketConnectionID];
  });
});
