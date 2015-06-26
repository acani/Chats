require 'test_helper'

class KeysTest < ChatsTest
  def test_keys_post
    # Create code
    phone = '2345678901'
    Chats::TextBelt.mock({'success' => true}) do
      post '/codes', {phone: phone}
    end
    code = get_code(phone)

    # Test no code
    post '/keys'
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test empty code
    post '/keys', {code: '', phone: ''}
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test invalid code
    post '/keys', {code: '123456'}
    assert_return [400, '{"message":"Code must be 4 digits."}']

    # Test no phone
    post '/keys', {code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test empty phone
    post '/keys', {phone: '', code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test invalid phone
    post '/keys', {phone: '1234567890', code: '1234'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test incorrect code
    incorrect_code = (code == '1234' ? '1235' : '1234')
    post '/keys', {phone: phone, code: incorrect_code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']

    # Test incorrect phone
    post '/keys', {phone: '2345678902', code: code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']

    # Test correct phone & code
    post '/keys', {phone: phone, code: code}
    assert_return [201, /\A\{"key":"[0-9a-f]{32}"\}\z/]

    # Confirm previous key creation
    assert_match /\A[0-9a-f]{32}\z/, get_key(phone)

    # Test that code only works once
    post '/keys', {phone: phone, code: code}
    assert_return [403, '{"message":"Code is incorrect or expired."}']
  end
end
