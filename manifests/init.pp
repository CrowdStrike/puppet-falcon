# @summary configures and installs CrowdStrike Falcon Sensor
#
# @example Basic usage
#   class { 'falcon':
#     cid            => '12345',
#     client_id      => '<client_id>',
#     client_secret  => '<client_secret>',
#     update_policy  => 'platform_default'
#     install_method => 'api'
#   }
#
# @param package_manage
#   Whether to install and manage the `falcon sensor`. Defaults to `true`.
#
# @param config_manage
#   Whether to manage the `falcon sensor` configuration. Defaults to `true`.
#
# @param service_manage
#   Whether to manage the service. Defaults to `true`.
#
#   > **_NOTE:_**  The falcon service requires the agent to be registered with the Customer CID in order to start.
#
# @param cid
#  The Customer CID to register the agent with. If not provided, the agent will not be registered. The falcon service can not be started
#  if cid is not configured. Defaults to `undef`.
#
#  Ignored if `config_manage` is set to `false`.
#
# @param install_method
#   The method used to install the `falcon sensor`. Defaults to `api`.
#
#   Valid values:
#     - `api`
#     - `local`
#
#   When `api` is selected, the falcon api will be used to download the correct version of the falcon sensor.
#
#   When `local` is selected, a package resource is created with the values passed in the `package_options` parameter.
#
# @param client_id
#   The client id used to authenticate with the Falcon API. Defaults to `undef`.
#
#   Required if `install_method` is set to `api` and ignored if `install_method` is set to `local`.
#
# @param client_secret
#   The client secret used to authenticate with the Falcon API. Defaults to `undef`.
#
#   Required if `install_method` is set to `api` and ignored if `install_method` is set to `local`.
#
# @param version_manage
#   Rather or not puppet should enforce a specific version and do upgrades/downgrades. Defaults to `false`.
#
#   Ignored if `install_method` is set to `local`.
#
#   > **_NOTE:_**  If you use update policies to manage the version, you should set this to `false` to prevent puppet
#     and the falcon platform from conflicting.
#
# @param falcon_cloud
#  The name of the cloud to use for the Falcon API. Defaults to `api.crowdstrike.com`
#
#  Ignored if `install_method` is set to `local`.
#
# @param update_policy
#   The update policy to use to determine the package version to download and install. Defaults to `undef`.
#
#   `update_policy` takes precedence over `version_decrement`.
#
#   Ignored if `install_method` is set to `local`.
#
# @param sensor_tmp_dir
#  The directory to use to stage the sensor package. Defaults to `/tmp` (or `%TEMP%` on Windows).
#
#  Ignored if `install_method` is set to `local`.
#
# @param version
#  The version of the sensor to install. When provided `update_policy` and `version_decrement` will be ignored. Defaults to `undef`.
#
#  Ignored if `install_method` is set to `local`.
#
# @param version_decrement
#  The number of versions to decrement from the latest version. When `version`, `update_policy` are not provided
#  this will be used to determine the version to download and install. Defaults to `0`.
#
#  Ignored if `install_method` is set to `local`.
#
# @param cleanup_installer
#   Rather or not to remove the sensor install package after use. Defaults to `true`.
#
#   Ignored if `install_method` is set to `local`.
#
# @param provisioning_token
#  The provisioning token to use to register the sensor with the Falcon API. Defaults to `undef`.
#
# @param package_name
#  The name of the package to install. Defaults to the valid service name for the OS.
#
#  `package_options` will override if you pass in a package name.
#
#  Ignored if `install_method` is set to `local`.
#
# @param package_options
#  Allows you to override any package attribute. Defaults to `{}`.
#
# @param service_enable
#  Whether to enable the service. Defaults to `true`.
#
#  Ignored if `service_manage` is set to `false`.
#
# @param service_name
#  The name of the service to manage. Defaults to the valid service name for the OS.
#
#  Ignored if `service_manage` is set to `false`.
#
# @param service_ensure
#  The desired service state. Defaults to `running`.
#
#  Ignored if `service_manage` is set to `false`.
#
# @param proxy_host
#  The proxy host for the falcon agent to use. Defaults to `undef`.
#
# @param proxy_port
#  The proxy port for the falcon agent to use. Defaults to `undef`.
#
# @param proxy_enabled
#  Whether proxy is enabled. Defaults to `undef`.
#
# @param tags
#  List of tags to apply to the sensor. Defaults to `undef`.
#
# @param tag_membership
#  Rather specified tags should be treated as a complete list `inclusive` or as a list of tags to add to the existing list `minimum`.
#  `inclusive` will ensure the sensor has only the tags specified in `tags` removing any tags that are not specified. `minimum` will
#  ensure the sensor has the tags specified in `tags` but will not remove any existing tags. Defaults to `minimum`.
#
class falcon (
  # falcon::config
  Optional[Variant[Sensitive[String], String]] $cid = $falcon::params::cid,
  Optional[Boolean] $config_manage               = $falcon::params::config_manage,
  Optional[String] $provisioning_token           = $falcon::params::provisioning_token,

  Optional[String] $proxy_host                   = $falcon::params::proxy_host,
  Optional[Numeric] $proxy_port                  = $falcon::params::proxy_port,
  Optional[Boolean] $proxy_enabled               = $falcon::params::proxy_enabled,

  Optional[Array[String]] $tags                  = $falcon::params::tags,
  Optional[Enum['inclusive', 'minimum']] $tag_membership = $falcon::params::tag_membership,

  # falcon::install
  String $falcon_cloud                           = $falcon::params::falcon_cloud,
  Optional[String] $version                      = $falcon::params::version,
  Optional[String] $package_name                 = $falcon::params::package_name,
  Optional[String] $update_policy                = $falcon::params::update_policy,
  Optional[String] $sensor_tmp_dir               = $falcon::params::sensor_tmp_dir,
  Optional[Sensitive] $client_id                 = $falcon::params::client_id,
  Optional[Sensitive] $client_secret             = $falcon::params::client_secret,
  Optional[Boolean] $version_manage              = $falcon::params::version_manage,
  Optional[Boolean] $package_manage              = $falcon::params::package_manage,
  Optional[Boolean] $cleanup_installer           = $falcon::params::cleanup_installer,
  Optional[Numeric] $version_decrement           = $falcon::params::version_decrement,
  Optional[Enum['api', 'local']] $install_method = $falcon::params::install_method,
  Hash[String, Any] $package_options             = $falcon::params::package_options,

  # falcon::service
  Optional[Boolean] $service_manage              = $falcon::params::service_manage,
  Optional[Boolean] $service_enable              = $falcon::params::service_enable,
  Optional[String] $service_name                 = $falcon::params::service_name,
  Optional[String] $service_ensure               = $falcon::params::service_ensure,

) inherits falcon::params {

  contain falcon::install
  contain falcon::config
  contain falcon::service

  Class['falcon::install']
  -> Class['falcon::config']
  ~> Class['falcon::service']
}
