# @summary configures and install CrowdStrike Falcon Sensor
#
# @example Basic usage
#   class { 'falcon':
#     cid => '12345',
#     client_id => '<client_id>',
#     client_secret => '<client_secret>',
#     update_policy => 'platform_default'
#   }
#
# @param cid
#  The Customer CID to register with
# @param install_method
#   The method used to get the Sensor Package.
# @param client_id
#   The client id used to authenticate with the Falcon API
# @param client_secret
#   The client secret used to authenticate with the Falcon API
# @param manage
#   Rather or not puppet should enforce a specific version and do upgrades/downgrades.
# @param falcon_cloud
#  The name of the cloud to use for the Falcon API
# @param update_policy
#   The update policy to use to determine the version to download and install. `version` has precedence over `update_policy`.
# @param sensor_source
#  When provided the source will be passed to the package instead of downloading the sensor based on version or update policy
# @param sensor_tmp_dir
#  The directory to use to stage the sensor package
#  `/tmp` for linux/macOS and `%TEMP%` for Windows
# @param version
#  The version of the sensor to install. When provided `update_policy` and `version_decrement` will be ignored
# @param version_decrement
#  The number of versions to decrement from the latest version. When `version`, `update_policy`, or `sensor_source` are not provided
#  this will be used to determine the version to download and install.
# @param cleanup_installer
#   Rather or not to remove the sensor install package after use.
# @param provisioning_token
#  The provisioning token to use to register the sensor with the Falcon API
class falcon::install (
  String $cid,
  Optional[Sensitive] $client_id = undef,
  Optional[Sensitive] $client_secret = undef,
  String $falcon_cloud = 'api.crowdstrike.com',
  Optional[Enum['api', 'local']] $install_method = 'api',
  Optional[Boolean] $manage = false,
  Optional[String] $version = undef,
  Optional[String] $update_policy = undef,
  Optional[String] $sensor_tmp_dir = undef,
  Optional[Numeric] $version_decrement = 0,
  Optional[Boolean] $cleanup_installer = true,
  Optional[String] $provisioning_token = undef,
) {

  $sensor_package_name = $facts['kernel'] ? {
    'Linux' => 'falcon-sensor',
    'Darwin' => 'falcon',
    'windows' => 'CrowdStrike Windows Sensor'
  }

  if $install_method == 'api' {
    if !($client_id and $client_secret) {
      fail("client_id and client_secret are required when install_method is 'api'")
    }

    $config = {
      'version' => $version,
      'falcon_cloud' => $falcon_cloud,
      'update_policy' => $update_policy,
      'sensor_tmp_dir' => $sensor_tmp_dir,
      'version_decrement' => $version_decrement,
    }

    $info = falcon::sensor_download_info($client_id, $client_secret, $config)

    sensor_download { 'Download Sensor Package':
      ensure       => 'present',
      manage       => $manage,
      version      => $info['version'],
      file_path    => $info['file_path'],
      sha256       => $info['sha256'],
      bearer_token => $info['bearer_token'],
      falcon_cloud => $falcon_cloud,
      before       => Package['Install Falcon Sensor']
    }

    if $manage {
      $_ensure = $info['version']
    } else {
      $_ensure = 'present'
    }
  }

  package { 'Install Falcon Sensor':
    ensure => $_ensure,
    name   => $sensor_package_name,
    source => $info['file_path'],
  }

  if $install_method == 'api' and $cleanup_installer {
    file { 'Ensure Package is Removed':
      ensure  => 'absent',
      path    => $info['file_path'],
      require => Package['Install Falcon Sensor']
    }
  }

  if $facts['kernel'] == 'Linux' {
    if $facts['kernel'] == 'Linux' and $cid {
      falconctl { 'Configure Falcon':
        cid     => $cid,
        require => Package['Install Falcon Sensor'],
        notify  => Service['falcon-sensor']
      }
    }

    service { 'falcon-sensor':
      ensure  => 'running',
      require => Package['Install Falcon Sensor']
    }
  }
}
