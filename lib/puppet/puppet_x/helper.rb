require 'uri'
require 'net/http'
require 'json'
require 'cgi'

# Build the query string used to filter sensor installers
def build_sensor_installer_query(platform_name:, os_name: nil, version: nil)
  query = "platform:'#{platform_name.downcase}'"

  unless version.nil?
    query += "+version:'#{version}'"
  end

  unless os_name.nil?
    query += "+os:'#{os_name.capitalize}'"
  end

  query
end

# Grabs the platform name that the falcon api expects
def platform(scope)
  if scope['facts']['os']['macosx']
    return 'Mac'
  end

  scope['facts']['kernel'].capitalize
end
