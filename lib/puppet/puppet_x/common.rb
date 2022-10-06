def to_boolean(str)
  str.casecmp('true').zero? || str.casecmp('1').zero?
end

def module_version
  metadata = JSON.parse(File.read(File.join(File.dirname(__FILE__), '..', '..', '..', 'metadata.json')))
  metadata['version']
end
