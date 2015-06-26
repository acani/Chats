class Chats
  # Create or update code with phone
  # curl -i -d phone=2102390602 http://localhost:5100/codes
  def codes_post
    # Validate phone
    phone = Rack::Request.new(@env).POST['phone']
    error = phone_invalid_response!(phone)
    return error if error

    $pg.with do |pg|
      pg.exec_params('SELECT * FROM codes_post($1)', [phone]) do |r|
        values = r.values[0]
        result = TextBelt.send({
          number: phone,
          message: "Your Chats code is " + values[1].rjust(4, '0')
        })
        if result['success']
          [values[0] ? 200 : 201, '']
        else
          [500, '{"message":"'+result['message']+'"}']
        end
      end
    end
  end
end
