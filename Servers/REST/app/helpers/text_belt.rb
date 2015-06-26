require 'net/http'

class Chats
  module TextBelt
    # Send SMS with TextBelt
    # TextBelt.send({
    #   number: '2102390602',
    #   message: 'Hello, World!'
    # })
    # curl -i -d number=2102390602 -d message='Hello, World!' http://textbelt.com/text
    def self.send(params)
      uri = URI('http://textbelt.com/text')
      response = Net::HTTP.post_form(uri, params)
      if response.instance_of? Net::HTTPOK
        JSON.parse(response.body)
      else
        {'success' => false, 'message' => "Couldn't send text message."}
      end
      # {'success' => true} # test
    end
  end
end
