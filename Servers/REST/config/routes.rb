class Chats
  def call(env)
    @env = env
    @response_headers = {}
    method = env['REQUEST_METHOD']

    return_value = case env['PATH_INFO']
    when '/codes'
      case method
      when 'POST' then codes_post
      end
    when '/keys'
      case method
      when 'POST' then keys_post
      end
    when '/me'
      case method
      when 'GET' then me_get
      when 'PATCH' then me_patch
      when 'DELETE' then me_delete
      end
    when '/presigned_post'
      case method
      when 'POST' then presigned_post_post
      end
    when '/sessions'
      case method
      when 'POST' then sessions_post
      when 'DELETE' then sessions_delete
      end
    when '/users'
      case method
      when 'GET' then users_get
      when 'POST' then users_post
      end
    end

    if return_value
      body = return_value[1]
      return_value[1] = [body]
      unless body.empty?
        @response_headers['Content-Type'] = 'application/json'
      end
      return_value.insert(1, @response_headers)
    else
      [404, {}, []]
    end
  end
end
