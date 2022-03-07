# @summary configures and install CrowdStrike Falcon Sensor
#
# @example Basic usage
#   class { 'falcon':
#     client_id => '<client_id>',
#     client_secret => '<client_secret>'
#     update_policy => 'platform_default'
#   }
#
# @param client_id
#   The client id used to authenticate with the Falcon API
# @param client_secret
#   The client secret used to authenticate with the Falcon API
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
class falcon::install (
  Sensitive $client_id,
  Sensitive $client_secret,
  String $falcon_cloud = 'api.crowdstrike.com',
  Optional[String] $version = undef,
  Optional[String] $update_policy = undef,
  Optional[String] $sensor_tmp_dir = undef,
  Optional[Numeric] $version_decrement = 0,
) {

  $config = {
    'version' => $version,
    'falcon_cloud' => $falcon_cloud,
    'update_policy' => $update_policy,
    'sensor_tmp_dir' => $sensor_tmp_dir,
    'version_decrement' => $version_decrement,
  }

  $info = falcon::sensor_download_info($client_id, $client_secret, $config)

  notify { 'title':
    message => $info
  }
}

include falcon::install
