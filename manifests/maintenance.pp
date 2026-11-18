# @summary
#   Applies a maintenance token so tamper protection does not block config and service changes.
#
# @api private
#
class falcon::maintenance {
  if $falcon::maintenance_token or $falcon::maintenance_token_api {
    if $facts['kernel'] != 'Linux' {
      fail('maintenance_token and maintenance_token_api are only supported on Linux')
    }

    if !$falcon::maintenance_token and !($falcon::client_id and $falcon::client_secret) {
      fail('client_id and client_secret are required when maintenance_token_api is true')
    }

    falcon_maintenance_token { 'falcon':
      ensure        => present,
      token         => $falcon::maintenance_token,
      client_id     => $falcon::client_id,
      client_secret => $falcon::client_secret,
      falcon_cloud  => $falcon::falcon_cloud,
      proxy_host    => $falcon::sensor_dl_proxy_host,
      proxy_port    => $falcon::sensor_dl_proxy_port,
    }
  }
}
