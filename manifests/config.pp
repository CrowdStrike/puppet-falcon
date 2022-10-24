# @summary 
#   This class handles the configuration of the falcon server.
#
# @api private
#
class falcon::config {
  if $falcon::config_manage and $facts['kernel'] == 'Linux' {
    falconctl { 'falcon':
      cid                => $falcon::cid,
      provisioning_token => $falcon::provisioning_token,
      proxy_host         => $falcon::proxy_host,
      proxy_port         => $falcon::proxy_port,
      proxy_enabled      => $falcon::proxy_enabled,
      tags               => $falcon::tags,
      tag_membership     => $falcon::tag_membership,
    }
  }
}
