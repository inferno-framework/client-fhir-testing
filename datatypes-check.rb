module CheckDatatypes
  def check_types(value, type)
    if type == "date"
      /([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?/.match?(value)
    elsif type == "token"
      /[^\s]+(\s[^\s]+)*/.match?(value)
    elsif type == "string"
      /[ \r\n\t\S]+/.match?(value)
    else
      nil
    end
  end
end
