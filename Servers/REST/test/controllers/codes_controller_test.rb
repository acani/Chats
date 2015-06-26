require 'test_helper'

class CodesTest < ChatsTest
  def test_codes_post
    # Test nil phone
    post '/codes'
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test empty phone
    post '/codes', {phone: ''}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test invalid phone
    post '/codes', {phone: '1234567890'}
    assert_return [400, '{"message":"Phone must be 10 digits."}']

    # Test unregistered phone
    unregistered_phone = '2345678901'
    Chats::TextBelt.mock({'success' => true}) do
      post '/codes', {phone: unregistered_phone}
    end
    assert_return [201, '']
    get_and_assert_code(unregistered_phone)

    # Test registered phone
    Chats::TextBelt.mock({'success' => true}) do
      post '/codes', {phone: @phone}
    end
    assert_return [200, '']
    code = get_and_assert_code(@phone)

    # Test registered phone update, error sending text
    Chats::TextBelt.mock({'success' => false, 'message' => "Error!"}) do
      post '/codes', {phone: @phone}
    end
    assert_return [500, '{"message":"Error!"}']
    code_new = get_and_assert_code(@phone)
    assert code != code_new
  end
end
