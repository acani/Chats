class Chats
  # Get all users
  # curl -i http://localhost:5100/users
  def users_get
    $pg.with do |pg|
      pg.exec('SELECT * FROM users_get()') do |r|
        users = []
        r.each_row do |t|
          user = {id: Integer(t[0]), name: {first: t[2], last: t[3]}}
          user[:picture_id] = t[1] if t[1]
          users.push(user)
        end
        [200, users.to_json]
      end
    end
  end

  # Sign up: Create user with phone, key, first_name, and last_name
  # curl -i -d phone=2102390602 -d key=abc123 -d picture_id=0123456789abcdef0123456789abcdef -d first_name=Matt -d last_name='Di Pasquale' http://localhost:5100/users
  def users_post
    params = Rack::Request.new(@env).POST
    phone = params['phone']
    key = params['key']

    if phone_valid?(phone) && uuid_valid?(key)
      # Validate picture_id, first_name, last_name, and email
      picture_id = params['picture_id']
      error = picture_id_invalid_response!(picture_id)
      return error if error

      first_name = params['first_name']
      error = name_invalid_response!('First', first_name)
      return error if error

      last_name = params['last_name']
      error = name_invalid_response!('Last', last_name)
      return error if error

      email = params['email']
      error = email_invalid_response!(email)
      return error if error

      $pg.with do |pg|
        pg.exec_params('SELECT * FROM users_post($1, $2, $3, $4, $5)', [phone, key, first_name, last_name, email]) do |r|
          if r.num_tuples == 1
            user_id = r.getvalue(0, 0)
            body = {access_token: build_access_token(user_id, key)}
            if picture_id
              fields = Aws::S3::Resource.new.bucket('acani-chats').presigned_post({
                acl: 'public-read',
                content_length_range: 0..102400,
                content_type: 'image/jpeg',
                key: "/users/#{user_id}/#{picture_id}.jpg"
              }).fields
              ['acl', 'Content-Type', 'key'].each { |f| fields.delete(f) }
              body[:fields] = fields
            end
            return [201, body.to_json]
          end
        end
      end
    end
    set_www_authenticate_header
    [401, '{"message":"Incorrect phone or key."}']
  end

  # Create a presigned post
  # https://devcenter.heroku.com/articles/direct-to-s3-image-uploads-in-rails#pre-signed-post
  # curl -i -d picture_id=0123456789abcdef0123456789abcdef http://localhost:5100/presigned_post
  def presigned_post_post
    params = Rack::Request.new(@env).POST

    picture_id = params['picture_id']
    error = picture_id_invalid_response!(picture_id)
    return error if error

    user_id = '23'
    body = {access_token: '23|0123456789abcdef0123456789abcdef'}
    if picture_id
      fields = Aws::S3::Resource.new.bucket('acani-chats').presigned_post({
        acl: 'public-read',
        content_length_range: 0..102400,
        content_type: 'image/jpeg',
        key: "/users/#{user_id}/#{picture_id}.jpg"
      }).fields
      ['acl', 'Content-Type', 'key'].each { |f| fields.delete(f) }
      body[:fields] = fields
    end
    return [201, body.to_json]
  end
end
