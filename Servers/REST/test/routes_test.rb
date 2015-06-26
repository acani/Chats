require 'test_helper'

class RoutesTest < ChatsTest
  def test_not_found
    get '/bad_path'
    assert_return 404

    get '/sessions' # bad method
    assert_return 404

    assert_raises(URI::InvalidURIError) { get "/users/\n/cool" }
  end
end
