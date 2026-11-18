# @summary
#   Clears the maintenance token applied by falcon::maintenance.
#
# @api private
#
class falcon::maintenance_cleanup {
  if $falcon::maintenance_token or $falcon::maintenance_token_api {
    falcon_maintenance_token { 'falcon cleanup':
      ensure => absent,
    }
  }
}
