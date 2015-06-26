require 'test_helper'

class SessionsTest < ChatsTest
  def test_sessions_post
    # Create code
    Chats::TextBelt.mock({'success' => true}) do
      post '/codes', {phone: @phone}
    end
    code = get_code(@phone)

    # Test no code
    post '/sessions'
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test empty code
    post '/sessions', {code: ''}
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test invalid code
    post '/sessions', {code: '123456'}
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test no phone
    post '/sessions', {code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test empty phone
    post '/sessions', {phone: '', code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test invalid phone
    post '/sessions', {phone: '1234567890', code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test incorrect code
    incorrect_code = (code == '1234' ? '1235' : '1234')
    post '/sessions', {phone: @phone, code: incorrect_code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']

    # Test incorrect phone
    post '/sessions', {phone: '2102390603', code: code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']

    # Test correct phone & code
    post '/sessions', {phone: @phone, code: code}
    assert_return [201, /\A\{"access_token":"1\|[0-9a-f]{32}"\}\z/]

    # Test that code only works once
    post '/sessions', {phone: @phone, code: code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']
  end

  def test_sessions_delete
    # Test invalid access_token
    authorize_user('invalid-access_token') do
      delete '/sessions'
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    # Test incorrect access_token
    authorize_user('9|12345678901234567890123456789012') do
      delete '/sessions'
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    # Test correct access_token
    authorize_user(@access_token) do
      delete '/sessions'
      assert_return 200
      get '/me'
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end
  end
end
