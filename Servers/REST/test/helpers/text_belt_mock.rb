class Chats
  module TextBelt
    def self.mock(result)
      mock = MiniTest::Mock.new
      mock.expect(:send, result, [Hash])

      Chats.const_mock(:TextBelt, mock) do
        yield
      end

      mock.verify
    end
  end

  def self.const_mock(const, mock)
    temp = const_get(const)
    const_set_silent(const, mock)
    yield
  ensure
    const_set_silent(const, temp)
  end

  # helper

  def self.const_set_silent(const, value)
    temp = $VERBOSE
    $VERBOSE = nil
    const_set(const, value)
  ensure
    $VERBOSE = temp
  end
end
