# @summary 
#   This class handles falcon sensor package.
#
# @api private
#
class falcon::install {

  if $falcon::package_manage {

    if $falcon::install_method == 'api' {
      if !($falcon::client_id and $falcon::client_secret) {
        fail("client_id and client_secret are required when install_method is 'api'")
      }

      $config = {
        'version' => $falcon::version,
        'falcon_cloud' => $falcon::falcon_cloud,
        'update_policy' => $falcon::update_policy,
        'sensor_tmp_dir' => $falcon::sensor_tmp_dir,
        'version_decrement' => $falcon::version_decrement,
      }

      $info = falcon::sensor_download_info($falcon::client_id, $falcon::client_secret, $config)

      if $falcon::version_manage or ($facts['falcon'].dig('version') in ['absent', undef]){
          sensor_download { 'Download Sensor Package':
            ensure         => 'present',
            version_manage => $falcon::version_manage,
            version        => $info['version'],
            file_path      => $info['file_path'],
            sha256         => $info['sha256'],
            bearer_token   => $info['bearer_token'],
            falcon_cloud   => $falcon::falcon_cloud,
            before         => Package['falcon']
        }
      }

      if $falcon::version_manage {
        $ensure = $info['version']
      } else {
        $ensure = 'present'
      }

      if $falcon::cleanup_installer {
        file { 'Ensure Package is Removed':
          ensure  => 'absent',
          path    => $info['file_path'],
          require => Package['falcon']
        }
      }

      $package_options = {
        'ensure' => $ensure,
        'name'   => $falcon::package_name,
        'source' => $info['file_path'],
      } + $falcon::package_options
    }

    if $falcon::install_method == 'local' {
      $package_options = { 'name' => $falcon::package_name } + $falcon::package_options
    }

    if $facts['kernel'] == 'windows' {
      unless $falcon::cid {
        fail('CID is required to install the Falcon Sensor on Windows')
      }
      $_package_options = empty($falcon::provisioning_token) ? {
        false   => {'install_options' => ['/install', '/quiet', '/norestart', "CID=${falcon::cid}", "ProvToken=${falcon::provisioning_token}"] } + $package_options, # lint:ignore:140chars
        default => {'install_options' => ['/install', '/quiet', '/norestart', "CID=${falcon::cid}"] } + $package_options,
      }
    } else {
      $_package_options = $package_options
    }

    package { 'falcon':
      * => $_package_options
    }
  }
}
