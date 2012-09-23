var WebSocketServer                    = require('ws').Server,
    web_socket_server                  = new WebSocketServer({port: 5000, disableHixie: true}),
    web_socket_connections             = {},
    web_socket_connections_primary_key = -1,
    apns                               = require('apn'),
    apns_connection                    = new apns.Connection({cert: 'apns/development_cer.pem', key: 'apns/development_p12.pem', gateway: 'gateway.sandbox.push.apple.com'}),
    // apns_connection                    = new apns.Connection({cert: 'apns/production_cer.pem', key: 'apns/production_p12.pem'}),
    redis_client                       = require('redis').createClient(process.env.REDIS_PORT, process.env.REDIS_HOST);

// $ redis-cli -h <hostname> -p <port> -a <password>
redis_client.auth(process.env.REDIS_AUTH, function(error) { if (error) throw error; });


// Message Type
// TODO: Condense _AND_DEVICE_TOKEN_CONNECT into one.
var USERS_NEAREST_GET                            = 0,
    USERS_NEAREST_GET_AND_DEVICE_TOKEN_CONNECT   = 1,
    MESSAGES_NEWEST_GET                          = 2,
    MESSAGES_NEWEST_GET_AND_DEVICE_TOKEN_CONNECT = 3,
    DEVICE_TOKEN_CONNECT                         = 4,
    DEVICE_TOKEN_SAVE                            = 5,
    DEVICE_TOKEN_UPDATE                          = 6,
    MESSAGE_TEXT_SEND                            = 7,
    MESSAGE_TEXT_RECEIVE                         = 8;


// WebSocket Server
web_socket_server.on('connection', function(web_socket_connection) {

  // Add newly created web_socket_connection to web_socket_connections.
  var web_socket_connection_id = ++web_socket_connections_primary_key;
  web_socket_connections[web_socket_connection_id] = web_socket_connection;
  var device_token = null;

  web_socket_connection.on('message', function(message) {

    // console.log("message: " + message);

    // Functions
    function sendUsersNearest() {
      // TODO: Sort by nearest (MongoDB).
      // TODO: Limit to 50 (sorted set).
      redis_client.smembers('deviceTokens', deviceToken, function(error, users_nearest) {
        if (error) throw error;
        if (device_token) {
          var device_token_index = users_nearest.indexOf(device_token);
          if (device_token_index === -1) {
            throw "Can't find device_token in deviceTokens"
          } else {
            users_nearest.splice(device_token_index, 1); // removes me
          }
        }
        web_socket_connection.send(USERS_NEAREST_GET+'|'+JSON.stringify(users_nearest));
      });
    }

    function sendMessagesNewest(messagesLength) {
      redis_client.llen('messages', function(error, messages_length) {
        if (error) throw error;
        var messages_new_length = messages_length - messagesLength;
        if (messages_new_length) {
          redis_client.lrange('messages', (messages_new_length > 50 ? messages_length-50 : messagesLength), messages_length-1, function(error2, messages_newest) {
            if (error2) throw error2;
            if (messages_newest) {
              web_socket_connection.send(MESSAGES_NEWEST_GET+'|'+messages_length+'|'+JSON.stringify(messages_newest));
            }
          });
        } else {
          web_socket_connection.send(MESSAGES_NEWEST_GET.toString());
        }
      });
    };

    function deviceTokenConnect(deviceToken) {
      redis_client.sadd('deviceTokensConnected', deviceToken, function(error, reply) {
        if (error) throw error;
        device_token = deviceToken;
      });
    };

    // Parse out message_type & message_content from message.
    var index_of_next_pipe = message.indexOf('|');
    var message_type, message_content;
    if (index_of_next_pipe === -1) {
      message_type    = parseInt(message);
      message_content = message;
    } else {
      message_type    = parseInt(message.substring(0, index_of_next_pipe)),
      message_content = message.substring(index_of_next_pipe+1);
    }

    switch (message_type) {

      case USERS_NEAREST_GET:
      // Client messages, immediately after connecting, to get users_nearest.
      // Server replies with users_nearest, limited to 50.
      //
      // Client Message: message_type,               e.g., USERS_NEAREST_GET
      // Server Reply:   message_type|users_nearest, e.g., USERS_NEAREST_GET|["c9a632...","473aba..."]
      //   - If Empty:   message_type|[]             i.e., USERS_NEAREST_GET|[]
      //
      // users_nearest: array of deviceTokens (for now)
      sendUsersNearest();
      break;

      case USERS_NEAREST_GET_AND_DEVICE_TOKEN_CONNECT:
      // Same as USERS_NEAREST_GET. Add connect device_token.
      //
      // Client Message: message_type|deviceToken, e.g., USERS_NEAREST_GET_AND_DEVICE_TOKEN_CONNECT|c9a632...
      sendUsersNearest();
      deviceTokenConnect(message_content /* deviceToken */);
      break;

      case MESSAGES_NEWEST_GET:
      // TODO: Rm messages_length from reply.
      // TODO: Rm messages_length from reply.
      
      // Client messages, immediately after connecting, to get messages_newest.
      // Server replies with messages_newest, limited to 50.
      //
      // Client Message: message_type|messagesLength,                  e.g., MESSAGES_NEWEST_GET|5
      // Server Reply:   message_type|messages_length|messages_newest, e.g., MESSAGES_NEWEST_GET|7|["978307200.0|Hi","978307201.0|Hey"]
      //   - If Empty:   message_type,                                 i.e., MESSAGES_NEWEST_GET
      //
      // messagesLength:  client's last received messages_length or 0, incremented every time client sends/receives a message
      // messages_length: server's 'messages' list length
      // messages_newest: array of strings with format: "sent_timestamp|messageText" (See MESSAGE_TEXT_SEND)
      sendMessagesNewest(message_content /* messagesLength */);
      break;

      case MESSAGES_NEWEST_GET_AND_DEVICE_TOKEN_CONNECT:
      // Same as MESSAGES_NEWEST_GET. Add connect device_token.
      //
      // Client Message: message_type|messagesLength|deviceToken, e.g., MESSAGES_NEWEST_GET_AND_DEVICE_TOKEN_CONNECT|5|c9a632...

      // Parse out arguments from message_content.
      index_of_next_pipe = message_content.indexOf('|');
      var messagesLength = message_content.substring(0, index_of_next_pipe),
          deviceToken    = message_content.substring(index_of_next_pipe+1);

      sendMessagesNewest(messagesLength);
      deviceTokenConnect(deviceToken);
      break;

      case DEVICE_TOKEN_SAVE:
      // Client sends this message to save its newDeviceToken.
      //
      // Client Message: message_type|newDeviceToken, e.g., DEVICE_TOKEN_SAVE|c9a632...
      //
      // deviceToken: used with Apple Push Notification Service (APNs)
      redis_client.sadd('deviceTokens', message_content, function(error, reply) {
        if (error) throw error;
        deviceTokenConnect(message_content);
      });
      break;

      case DEVICE_TOKEN_UPDATE:
      // Client sends this message to update its deviceToken.
      //
      // Client Message:  message_type|deviceToken|newDeviceToken, e.g., DEVICE_TOKEN_UPDATE|c9a632...|473aba...
      //
      // deviceToken: see DEVICE_TOKEN_SAVE

      // Parse out arguments from message_content.
      index_of_next_pipe = message_content.indexOf('|');
      var deviceToken    = message_content.substring(0, index_of_next_pipe);

      // TODO: Use Reids transactions here.
      redis_client.srem('deviceTokens', deviceToken, function(error, reply) {
        if (error) throw error;
        var newDeviceToken = message_content.substring(index_of_next_pipe+1);
        redis_client.sadd('deviceTokens', newDeviceToken, function(error, reply) {
          if (error) throw error;
          redis_client.srem('deviceTokensConnected', deviceToken, function(error, reply) {
            if (error) throw error;
            deviceTokenConnect(newDeviceToken);
          });
        });
      });
      break;

      case MESSAGE_TEXT_SEND:
      // Client messages to send messageText.
      // Server replies with confirmation and message sent_timestamp.
      // Server broadcasts message to all other web_socket_connections.
      //
      // Client Message:   message_type|messagesSendingKey|messageText,    e.g., MESSAGE_TEXT_SEND|0|Hi
      // Server Reply:     message_type|messagesSendingKey|sent_timestamp, e.g., MESSAGE_TEXT_SEND|0|978307200.0
      // Server Broadcast: message_type|sent_timestamp|messageText,        e.g., MESSAGE_TEXT_RECEIVE|978307200.0|Hi
      //
      // messagesSendingKey: key of message in client's _messagesSendingDictionary, which allows sending multiple messages simultaneously
      // sent_timestamp:     server's time interval, in seconds (double), since 1970 on receipt of message

      // Parse out arguments from message_content.
      index_of_next_pipe     = message_content.indexOf('|');
      var messagesSendingKey = message_content.substring(0, index_of_next_pipe);
      var messageText        = message_content.substring(index_of_next_pipe+1);

      // Set sent_message to 'sent_timestamp|messageText'.
      var sent_timestamp = Date.now()/1000;
      var sent_message = sent_timestamp+'|'+messageText;

      // Save sent_message to Redis.
      redis_client.rpush('messages', sent_message, function(error, reply) {
        if (error) throw error;

        // Send sent_timestamp back to client.
        web_socket_connection.send(MESSAGE_TEXT_SEND+'|'+messagesSendingKey+'|'+sent_timestamp);

        // Broadcast message to other web_socket_connections.
        for (var web_socket_connection_key in web_socket_connections) {
          if (web_socket_connection_key !== web_socket_connection_id) {
            web_socket_connections[web_socket_connection_key].send(MESSAGE_TEXT_RECEIVE+'|'+sent_message); // TODO: Should we check for error?
          }
        }

        // Send push notifications to all deviceTokensDisconnected.
        redis_client.sdiff('deviceTokens', 'deviceTokensConnected', function(error, deviceTokensDisconnected) {
          if (error) throw error;
          if (deviceTokensDisconnected.length) {
            var apns_notifcation = new apns.Notification();
            apns_notifcation.expiry = Math.floor(Date.now() / 1000) + 3600; // expires 1 hour from now
            apns_notifcation.badge = 3;
            apns_notifcation.sound = "ping.aiff";
            apns_notifcation.alert = "You have a new message";

            for (var deviceToken in deviceTokensDisconnected) {
                apns_notifcation.device = new apns.Device(deviceToken);
                apns_connection.sendNotification(apns_notifcation);
            }
          }
        });
      });
      break;

      // case MESSAGE_TEXT_RECEIVE: // implemented by client
    }
  });

  web_socket_connection.on('close', function() {
    if (device_token) {
      redis_client.srem('deviceTokensConnected', device_token, function(error, reply) {
        if (error) throw error;
        delete web_socket_connections[web_socket_connection_id];
      });
    }
  });
});
