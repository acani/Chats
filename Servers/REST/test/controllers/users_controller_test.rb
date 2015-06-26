require 'test_helper'

class UsersTest < ChatsTest
  def test_users_get
    get '/users'
    assert_return /\A\[\{"id":1,"name":\{"first":"Matt","last":"Di Pasquale"\},"picture_id":"[0-9a-f]{32}"\}\]\z/
  end

  def test_users_post
    # Create code
    phone = '2102390603'
    Chats::TextBelt.mock({'success' => true}) do
      post '/codes', {phone: phone}
    end
    code = get_code(phone)

    # Create key
    post '/keys', {phone: phone, code: code}
    key = get_key(phone)

    valid_auth = {phone: phone, key: key}
    valid_fields = {first_name: 'John', last_name: 'Appleseed', email: 'john@gmail.com'}
    unauthorized_response = [
      401,
      {'WWW-Authenticate' => 'Basic realm="Chats"'},
      '{"message":"Incorrect phone or key."}'
    ]

    # Test no phone or key
    post '/users'
    assert_return unauthorized_response

    # Test invalid phone
    post '/users', {phone: '123', key: key}.merge(valid_fields)
    assert_return unauthorized_response

    # Test invalid key
    post '/users', {phone: phone, key: 'abc123'}.merge(valid_fields)
    assert_return unauthorized_response

    # Test invalid phone & key
    post '/users', {phone: '123', key: 'abc123'}.merge(valid_fields)
    assert_return unauthorized_response

    # Test incorrect phone
    post '/users', {phone: '2345678902', key: key}.merge(valid_fields)
    assert_return unauthorized_response

    # Test incorrect key
    post '/users', {phone: phone, key: SecureRandom.hex}.merge(valid_fields)
    assert_return unauthorized_response

    # Test incorrect phone & key
    post '/users', {phone: '2345678902', key: SecureRandom.hex}.merge(valid_fields)
    assert_return unauthorized_response

    ### Test correct phone & key

    # Test no first_name
    post '/users', valid_auth
    assert_return [400, '{"message":"First name must be between 1 & 50 characters."}']

    # Test empty first_name
    post '/users', valid_auth.merge(first_name: '')
    assert_return [400, '{"message":"First name must be between 1 & 50 characters."}']

    # Test no last_name
    post '/users', valid_auth.merge(first_name: 'Matt')
    assert_return [400, '{"message":"Last name must be between 1 & 50 characters."}']

    # Test empty last_name
    post '/users', valid_auth.merge({first_name: 'Matt', last_name: ''})
    assert_return [400, '{"message":"Last name must be between 1 & 50 characters."}']

    # Test correct valid params
    post '/users', valid_auth.merge(valid_fields)
    assert_return [201, /\A\{"access_token":"2\|[0-9a-f]{32}"\}\z/]

    # Confirm previous user creation
    get '/users'
    assert_return /\A\[\{"id":1,"name":\{"first":"Matt","last":"Di Pasquale"\},"picture_id":"[0-9a-f]{32}"\},\{"id":2,"name":\{"first":"John","last":"Appleseed"\}\}\]\z/

    # Test that key only works once
    post '/users', valid_auth.merge(valid_fields)
    assert_return unauthorized_response
  end
end
