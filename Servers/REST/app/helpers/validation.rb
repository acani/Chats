class Chats
  def phone_invalid_response!(phone)
    unless phone_valid?(phone)
      [400, '{"message":"Phone must be 10 digits."}']
    end
  end

  def code_invalid_response!(code)
    unless code_valid?(code)
      [400, '{"message":"Code must be 4 digits."}']
    end
  end

  def picture_id_invalid_response!(picture_id)
    unless !picture_id || uuid_valid?(picture_id)
      [400, '{"message":"Picture ID must be 32 lowercase hexidecimal digits."}']
    end
  end

  def name_invalid_response!(name_type, name)
    unless !string_is_blank_after_strip!(name) && name.length <= 50
      [400, '{"message":"'+name_type+' name must be between 1 & 50 characters."}']
    end
  end

  def email_invalid_response!(email)
    unless !string_is_blank_after_strip!(email) && email.length.between?(3, 254) && email.include?('@')
      [400, '{"message":"Email must be between 3 & 254 characters and have an at sign."}']
    end
  end

  def phone_valid?(phone)
    return false unless phone
    !(phone !~ /\A[2-9]\d\d[2-9]\d{6}\z/)
  end

  def code_valid?(code)
    return false unless code
    if code =~ /\A\d{4}\z/
      code.sub!(/\A0+/, '') # strips leading zeros
      true
    else
      false
    end
  end

  def uuid_valid?(uuid)
    return false unless uuid
    !(uuid !~ /\A[0-9a-f]{32}\z/)
  end

  def string_is_blank_after_strip!(string)
    !string || (string.strip! || string).empty?
  end
end
