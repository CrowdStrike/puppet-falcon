# @summary 
#   This class contains the defaults for the falcon module.
#
# @api private
#
class falcon::params {
  # falcon::install
  $package_manage = true
  $package_name = $facts['kernel'] ? {
    'Linux' => 'falcon-sensor',
    'Darwin' => 'falcon',
    'windows' => 'CrowdStrike Windows Sensor'
  }
  $package_options = {}
  $install_method = 'api'
  $cleanup_installer = true
  $version_manage = false
  $client_id = undef
  $client_secret = undef
  $falcon_cloud = 'api.crowdstrike.com'
  $version = undef
  $update_policy = undef
  $version_decrement = 0
  $sensor_tmp_dir = $facts['kernel'] ? {
    'Linux' => '/tmp',
    'Darwin' => '/tmp',
    'windows' => 'C:\\Windows\\Temp'
  }

  $sensor_dl_proxy_host = undef
  $sensor_dl_proxy_port = undef

  # falcon::config
  $cid = undef
  $config_manage  = true
  $provisioning_token = undef

  $proxy_host = undef
  $proxy_port = undef
  $proxy_enabled = undef

  $tags = undef
  $tag_membership = 'minimum'

  # falcon::service
  $service_manage = true
  $service_ensure = 'running'
  $service_enable = true
  $service_name = $facts['kernel'] ? {
    'Linux' => 'falcon-sensor',
    'Darwin' => 'com.crowdstrike.falcon.UserAgent',
    'windows' => 'CSFalconService',
  }
}
