class Chats
  def build_access_token(user_id, session_id)
    user_id + '|' + session_id
  end

  def parse_authorization_header
    parts = authorization_parts
    if parts && parts.size > 0 && parts[0].casecmp('Bearer') == 0 && access_token = parts[1]
      result = access_token.split('|')
      result if result.size == 2
    end
  end

  def set_www_authenticate_header
    @response_headers['WWW-Authenticate'] = 'Basic realm="Chats"'
  end

  private

  def authorization_parts
    header = @env['HTTP_AUTHORIZATION']
    header.split(' ', 2) if header
  end
end
