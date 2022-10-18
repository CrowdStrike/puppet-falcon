def to_boolean(str)
  str.casecmp('true').zero? || str.casecmp('1').zero?
end