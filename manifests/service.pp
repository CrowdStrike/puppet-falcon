# @summary 
#   This class handles falcon sensor service.
#
# @api private
#
class falcon::service inherits falcon::params {
  if $falcon::service_manage {
    service { 'falcon':
      ensure => $falcon::service_ensure,
      name   => $falcon::service_name,
      enable => $falcon::service_enable,
    }
  }
}
