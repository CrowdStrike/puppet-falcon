require 'uri'
require 'net/http'
require 'json'
require 'cgi'

# Build the query string used to filter sensor installers
def build_sensor_installer_query(platform_name:, os_name: nil, version: nil, os_version: nil)
  query = "platform:'#{platform_name.downcase}'"

  unless os_version.nil?
    query += "+os_version:'#{os_version}'"
  end

  unless version.nil?
    query += "+version:'#{version}'"
  end

  unless os_name.nil?
    query += "+os:'#{os_name}'"
  end

  query
end

# Returns the platform name in the format expected by the falcon api
def platform(scope)
  if scope['facts']['os']['macosx']
    return 'Mac'
  end

  scope['facts']['kernel'].capitalize
end

# Returns the version of the os in the format expected by the falcon api
def os_version(scope, os_name)
  os_release_major = scope['facts']['os']['release']['major']

  if os_name.casecmp('macOS').zero? || os_name.casecmp('windows').zero?
    return nil
  end

  if os_name.casecmp('Debian').zero?
    return "*#{os_release_major}*"
  end

  if os_name.casecmp('Ubuntu').zero?
    return "*#{os_release_major.split('.')[0]}*"
  end

  if scope['facts']['architecture'].casecmp('arm64').zero?
    os_release_major + ' - arm64'
  end

  os_release_major
end

# Return the OS name in the format expected by the falcon api
def os_name(scope, platform_name)
  if platform_name.casecmp('mac').zero?
    return 'macOS'
  end

  if platform_name.casecmp('windows').zero?
    return 'Windows'
  end

  fact_os_name = scope['facts']['os']['name']

  if fact_os_name.casecmp('Amazon').zero?
    return 'Amazon Linux'
  end

  if ['RedHat', 'Scientific', 'Rocky', 'AlmaLinux'].any? { |base| fact_os_name.casecmp(base).zero? }
    return '*RHEL*'
  end

  if fact_os_name.casecmp('OracleLinux').zero?
    return '*Oracle*'
  end

  if fact_os_name.casecmp('CentOS').zero?
    return '*CentOS*'
  end

  fact_os_name
end
