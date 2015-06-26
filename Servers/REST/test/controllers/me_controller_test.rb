require 'test_helper'

class MeTest < ChatsTest
  def test_me_get
    # Test invalid access_token
    authorize_user('invalid-access_token') do
      get '/me'
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    # Test incorrect access_token
    authorize_user('9|12345678901234567890123456789012') do
      get '/me'
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    # Test correct access_token
    authorize_user(@access_token) do
       get '/me'
       assert_return [200, /\A\{"id":"1","picture_id":"[0-9a-f]{32}","name":\{"first":"Matt","last":"Di Pasquale"\},"phone":"#{@phone}"\}\z/]
    end
  end

  def test_patch_me
    # Test invalid access_token
    authorize_user('invalid-access_token') do
      patch '/me', {first_name: 'Matty', last_name: 'D'}
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    # Test incorrect access_token
    authorize_user('9|12345678901234567890123456789012') do
      patch '/me', {first_name: 'Matty', last_name: 'D'}
      assert_return [401, {'WWW-Authenticate' => 'Basic realm="Chats"'}, '']
    end

    authorize_user(@access_token) do
      # Test no fields
      patch '/me'
      assert_return [400, '{"message":"No changes requested."}']

      # Test empty first_name
      patch '/me', {first_name: ''}
      assert_return [400, '{"message":"First name must be between 1 & 50 characters."}']

      # Test empty last_name
      patch '/me', {last_name: ''}
      assert_return [400, '{"message":"Last name must be between 1 & 50 characters."}']

      # Test first_name only
      patch '/me', {first_name: 'Matty'}
      assert_return 200
      get '/me'
      assert_equal 'Matty', JSON.parse(last_response.body)['name']['first']

      # Test last_name only
      patch '/me', {last_name: 'D'}
      assert_return 200
      get '/me'
      assert_equal 'D', JSON.parse(last_response.body)['name']['last']

      # Test both names
      patch '/me', {first_name: 'Matt', last_name: 'Di Pasquale'}
      assert_return 200
      get '/me'
      assert_equal({'first' => 'Matt', 'last' => 'Di Pasquale'}, JSON.parse(last_response.body)['name'])
    end
  end

  # def test_delete_me
  #   # Test no access token
  #   delete '/me'
  #   assert_return 404
  #
  #   # Test user not found
  #   authorize_user('123456789012345678901234567890122') { delete '/me' }
  #   assert_return 401
  #
  #   # Test unauthorized
  #   authorize_user('123456789012345678901234567890121') { delete '/me' }
  #   assert_return 401
  #
  #   # Test successful delete
  #   authorize_user(@access_token) { delete '/me' }
  #   assert_return 200
  #   authorize_client { get '/users' }
  #   assert_return [200, '[]']
  # end
end
