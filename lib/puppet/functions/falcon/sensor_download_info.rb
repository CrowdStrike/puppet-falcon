require_relative '../../puppet_x/falconapi'
require_relative '../../puppet_x/helper'

# Get sensor info like install package SHA and version
Puppet::Functions.create_function(:'falcon::sensor_download_info') do
  # @param client_id the client id used to authenticate with the Falcon API
  # @param client_secret the client secret used to authenticate with the Falcon API
  # @param options used to determine how download information is retrieved
  #
  #   - `version` the version of the sensor to use
  #   - `falcon_cloud` the name of the cloud to use
  #   - `update_policy` the update policy to use
  #   - `sensor_tmp_dir` the temporary directory to use
  # @return [Hash] download information about the sensor
  #
  #   - `sha256` the SHA256 checksum of the sensor package
  #   - `version` the version of the sensor package
  #   - `os_name` the name of the operating system the sensor is for
  #   - `file_path` the fully qualified file path to download the sensor package to
  #   - `bearer_token` the bearer token used to authenticate with the Falcon API
  #   - `platform_name` the name of the platform the sensor is for
  # @example Calling the function
  #   falcon::sensor_download_info('client_id', 'client_secret', { 'falcon_cloud' => 'api.crowdstrike.com'})
  #
  dispatch :sensor_download_info do
    param 'Sensitive', :client_id
    param 'Sensitive', :client_secret
    param 'Hash', :options
    return_type 'Hash'
  end

  def sensor_download_info(client_id, client_secret, options)
    scope = closure_scope

    platform_name = platform(scope)
    os_name = os_name(scope, platform_name)
    os_version = os_version(scope, os_name)
    architecture = scope['facts']['architecture']

    falcon_api = FalconApi.new(falcon_cloud: options['falcon_cloud'], client_id: client_id, client_secret: client_secret)
    falcon_api.platform_name = platform_name

    # If version is provied, use it to get the sensor package info
    if options.key?('version') && !options['version'].nil?
      query = build_sensor_installer_query(platform_name: platform_name, version: version, os_name: os_name, os_version: os_version, architecture: architecture)
      installer = falcon_api.falcon_installers(query)[0]
    # If update_policy is provided, use it to get the sensor package info
    elsif options.key?('update_policy') && !options['update_policy'].nil?
      falcon_api.update_policy = options['update_policy']
      version = falcon_api.version_from_update_policy
      query = build_sensor_installer_query(platform_name: platform_name, version: version, os_name: os_name, os_version: os_version, architecture: architecture)
      installer = falcon_api.falcon_installers(query)[0]
    # If neither are provided, use the `version_decrement` to pull the n-x version for the platform and os`
    else
      query = build_sensor_installer_query(platform_name: platform_name, os_name: os_name, os_version: os_version, architecture: architecture)
      version_decrement = options['version_decrement']
      installers = falcon_api.falcon_installers(query)

      if version_decrement >= installers.length
        raise Puppet::Error, "The version_decrement is greater than the number of versions available for Platform: #{platform_name} and OS: #{os_name}"
      end

      installer = installers[version_decrement]
      version = installer['version']
    end

    file_path = File.join(options['sensor_tmp_dir'], installer['name'])

    # CrowdStrike API returns versions like 6.25.1302, but on linux once we install the package version is
    # 6.25.0-1302 so the below regex is used to make this change.
    # TODO: Check if macos and windows package version needs the same fix
    version = version.gsub(%r{\.(\d+)\.(\d+)}, '.\1.0-\2')
    version += ".el#{os_version}" if os_name.casecmp('*RHEL*').zero?
    version += ".amzn#{os_version}" if os_name.casecmp('Amazon Linux').zero?

    {
      'bearer_token' => falcon_api.bearer_token,
      'version' => version,
      'sha256' => installer['sha256'],
      'file_path' => file_path,
      'platform_name' => platform_name,
      'os_name' => os_name
    }
  end
end
