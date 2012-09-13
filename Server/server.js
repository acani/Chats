var WebSocketServer        = require('ws').Server,
    web_socket_server      = new WebSocketServer({port: 5000, disableHixie: true}),
    web_sockets            = {},
    web_socket_primary_key = -1,
    redis_client           = require('redis').createClient();

web_socket_server.on('connection', function(web_socket) {

  // Add newly created web_socket to web_sockets.
  var web_socket_id = ++web_socket_primary_key;
  web_sockets[web_socket_id] = web_socket;

  web_socket.on('message', function(message) {
    // console.log("message: " + message);

    var message_array = JSON.parse(message); // TODO: Rescue and return error.
    switch (message_array[0]) { // message type
      case 0: // Last 50 Messages: [type, messagesCount], e.g., [0, 5]
      // Send the last 50 messages after the specified messageID.
      redis_client.llen('messages', function(error, messages_length) {
        if (error) throw error;
        var new_messages_length = messages_length - message_array[1];
        if (new_messages_length) {
          redis_client.lrange('messages', -Math.min(50, new_messages_length), -1, function(error2, newest_messages) {
            if (error2) throw error2;
            if (newest_messages) {
              web_socket.send(JSON.stringify([0, messages_length, newest_messages.map(JSON.parse)]));
            }
          });
        } else {
          web_socket.send('[0]');
        }
      });
      break;

      case 1: // New Message: [type, "messageText", messagesSendingIndex], e.g., [1, "Hi", 0]
      // Set sent_message to [sentDate, "messageText"].
      var sent_date = Date.now()/1000;
      var sent_message = JSON.stringify([sent_date, message_array[1]]);

      // Save sent_message to Redis.
      redis_client.rpush('messages', sent_message, function(error, reply) {
        if (error) throw error;

        // Send sentDate back to client.
        web_socket.send('[2,'+sent_date+','+message_array[2]+']');

        // Broadcast message to other web_sockets.
        for (var web_socket_key in web_sockets) {
          if (web_socket_key != web_socket_id) {
            web_sockets[web_socket_key].send('[1,'+sent_message+']'); // TODO: Should we check for error?
          }
        }
      }); // TODO: Check errors.

      break;
    }
  });

  web_socket.on('close', function() {
    delete web_sockets[web_socket_id];
  });
});
