require 'uri'
require 'net/http'
require 'json'
require 'cgi'

# Build the query string used to filter sensor installers
def build_sensor_installer_query(platform_name:, os_name: nil, version: nil, os_version: nil, architecture: nil)
  query = "platform:'#{platform_name.downcase}'"

  query += "+os_version:'#{os_version}'" unless os_version.nil?

  unless architecture.nil?
    query += case architecture
             when 'x86_64', 'amd64', 'x64'
               "+os_version:!~'arm64'+os_version:!~'zLinux'"
             when 'arm64', 'aarch64', 'arm'
               "+os_version:~'arm64'"
             when 's390x'
               "+os_version:~'s390x'"
             else
               raise Puppet::Error, "Unsupported architecture: #{architecture}"
             end
  end

  query += "+version:'#{version}'" unless version.nil?

  query += "+os:'#{os_name}'" unless os_name.nil?

  query
end

# Returns the platform name in the format expected by the falcon api
def platform(scope)
  return 'Mac' if scope['facts']['os']['macosx']

  scope['facts']['kernel'].capitalize
end

# Returns the version of the os in the format expected by the falcon api
def os_version(scope, os_name)
  os_release_major = scope['facts']['os']['release']['major']

  return nil if os_name.casecmp('macOS').zero? || os_name.casecmp('windows').zero?

  return "*#{os_release_major}*" if os_name.casecmp('Debian').zero?

  return "*#{os_release_major.split('.')[0]}*" if os_name.casecmp('Ubuntu').zero?

  os_release_major
end

# Return the OS name in the format expected by the falcon api
def os_name(scope, platform_name)
  return 'macOS' if platform_name.casecmp('mac').zero?

  return 'Windows' if platform_name.casecmp('windows').zero?

  fact_os_name = scope['facts']['os']['name']

  return 'Amazon Linux' if fact_os_name.casecmp('Amazon').zero?

  rhel_base = ['RedHat', 'CentOS', 'OracleLinux', 'Scientific', 'Rocky', 'AlmaLinux']

  return '*RHEL*' if rhel_base.any? { |base| fact_os_name.casecmp(base).zero? }

  fact_os_name
end
