# @summary 
#   This class handles the configuration of the falcon server.
#
# @api private
#
class falcon::config {
  if $falcon::config_manage {
    falconctl { 'falcon':
      cid                => $falcon::cid,
      provisioning_token => $falcon::provisioning_token,
    }
  }
}
