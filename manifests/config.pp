# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include cloud_fail2ban::config
class cloud_fail2ban::config (
  Boolean $loglevel = 'INFO',
  Optional[String] $aws_access_key_id = undef,
  Optional[String] $aws_secret_access_key = undef,
  String $aws_region = 'us-west-2',
){
  file { 'Cloud_Fail2Ban AWS config dir':
    ensure => directory,
    path   => "${cloud_fail2ban::install::home}/.aws",
    owner  => 'cloudfail2ban',
    mode   => '0775',
  }

  file { 'Cloud_Fail2Ban AWS config':
    ensure  => file,
    path    => "${cloud_fail2ban::install::home}/.aws/config",
    owner   => 'cloudfail2ban',
    mode    => '0600',
    content => epp('cloud_fail2ban/aws/config'),
  }

  file { 'Cloud_Fail2Ban AWS credentials':
    ensure  => file,
    path    => "${cloud_fail2ban::install::home}/.aws/credentials",
    owner   => 'cloudfail2ban',
    mode    => '0600',
    content => epp('cloud_fail2ban/aws/credentials'),
  }
}
