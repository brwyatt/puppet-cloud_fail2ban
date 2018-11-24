# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include cloud_fail2ban::service
class cloud_fail2ban::service {
  ::systemd::unit_file { 'cloud_fail2ban.service':
    content => epp('cloud_fail2ban/cloud_fail2ban.service.epp'),
  }
  service { 'cloud_fail2ban':
    ensure => running,
  }

  Systemd::Unit_file['cloud_fail2ban.service'] ~> Service['cloud_fail2ban']
  Service['fail2ban'] ~> Service['cloud_fail2ban']
}
