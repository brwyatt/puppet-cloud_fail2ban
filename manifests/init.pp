# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include cloud_fail2ban
class cloud_fail2ban {
  class { 'cloud_fail2ban::install': }
  class { 'cloud_fail2ban::config': }
  class { 'cloud_fail2ban::service': }

  Class['cloud_fail2ban::install'] -> Class['cloud_fail2ban::config']
  Class['cloud_fail2ban::install'] ~> Class['cloud_fail2ban::service']
  Class['cloud_fail2ban::config'] ~> Class['cloud_fail2ban::service']
}
