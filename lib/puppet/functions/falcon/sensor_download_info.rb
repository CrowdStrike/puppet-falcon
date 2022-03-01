require_relative '../../puppet_x/falconapi'
require_relative '../../puppet_x/helper'

# Get sensor info like install package SHA and version
Puppet::Functions.create_function(:'falcon::sensor_download_info') do
  dispatch :sensor_download_info do
    param 'Sensitive', :client_id
    param 'Sensitive', :client_secret
    param 'Hash', :options
    return_type 'Hash'
  end

  def sensor_download_info(client_id, client_secret, options)
    scope = closure_scope

    platform_name = platform(scope)
    os_name = platform_name.casecmp('mac').zero? ? 'macOS' : scope['facts']['os']['name']

    falcon_api = FalconApi.new(falcon_cloud: options['falcon_cloud'], client_id: client_id, client_secret: client_secret)
    falcon_api.policy_name = options['update_policy']
    falcon_api.platform_name = platform_name

    version = falcon_api.version_from_policy_name
    query = build_sensor_installer_query(platform_name: platform_name, version: version, os_name: os_name)
    installers = falcon_api.falcon_installers(query)
    file_path = File.join(options['sensor_tmp_dir'], installers[0]['name'])
    falcon_api.download_installer(installers[0]['sha256'], file_path)

    {
      'bearer_token' => falcon_api.bearer_token,
      'version' => version,
      'sha256' => installers[0]['sha256'],
      'file_path' => file_path,
      'platform_name' => platform_name,
      'os_name' => os_name
    }
  end
end
