class Chats
  # Get me: id, picture_id, first_name, last_name
  # curl -i -H 'Authorization: Bearer 1|12345678901234567890123456789012' http://localhost:5100/me
  def me_get
    user_id, session_id = parse_authorization_header
    if user_id
      $pg.with do |pg|
        pg.exec_params('SELECT * FROM me_get($1, $2)', [user_id, session_id]) do |r|
          if r.num_tuples == 1
            values = r.values[0]
            picture_id = values[1] ? '","picture_id":"'+values[1] : ''
            return [200, '{"id":"'+values[0]+picture_id+'","name":{"first":"'+values[2]+'","last":"'+values[3]+'"},"phone":"'+values[4]+'"}']
          end
        end
      end
    end
    set_www_authenticate_header
    [401, '']
  end

  # Update me: first_name, last_name
  # curl -i -X PATCH -H 'Authorization: Bearer 1|12345678901234567890123456789012' -d phone='2102390603' -d first_name=John -d last_name='Appleseed' http://localhost:5100/me
  def me_patch
    user_id, session_id = parse_authorization_header
    if user_id
      params = Rack::Request.new(@env).POST
      first_name = params['first_name']
      last_name = params['last_name']

      # No change requested
      unless first_name || last_name
        return [400, '{"message":"No changes requested."}']
      end

      # Reject blank strings
      if first_name
        error = name_invalid_response!('First', first_name)
        return error if error
      end
      if last_name
        error = name_invalid_response!('Last', last_name)
        return error if error
      end

      $pg.with do |pg|
        pg.exec_params('SELECT me_patch($1, $2, $3, $4)', [user_id, session_id, first_name, last_name]) do |r|
          if r.num_tuples == 1
            return [200, '']
          end
        end
      end
    end
    set_www_authenticate_header
    [401, '']
  end

  # Delete my account
  # curl -i -X DELETE -H 'Authorization: Bearer 1|12345678901234567890123456789012' http://localhost:5100/me
  def me_delete
    user_id, session_id = parse_authorization_header
    if user_id
      $pg.with do |pg|
        pg.exec_params('SELECT me_delete($1, $2)', [user_id, session_id]) do |r|
          if r.num_tuples == 1
            return [200, '']
          end
        end
      end
    end
    set_www_authenticate_header
    [401, '']
  end
end
