require 'test_helper'

class TextBeltTest < ChatsTest
  def test_send
    assert Chats::TextBelt.respond_to?(:send)
  end
end
