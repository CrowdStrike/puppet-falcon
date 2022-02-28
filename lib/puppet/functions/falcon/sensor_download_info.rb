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

    api = FalconApi.new(options['falcon_cloud'], client_id, client_secret, scope)

    api.policy_name = 'platform_default'

    version = api.version_from_policy_name
    query = api.build_sensor_api_query

    installers = api.falcon_installers(query)

    {
      'bearer_token' => api.bearer_token,
      'version' => version,
      'sha256' => installers[0]['sha256']
    }
  end
end
