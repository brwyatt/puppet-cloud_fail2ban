# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include cloud_fail2ban::install
class cloud_fail2ban::install (
  String $home = '/opt/cloud_fail2ban',
  String $git_repo = 'https://github.com/brwyatt/Cloud-Fail2Ban.git',
  String $git_branch = 'master',
  Optional[String] $git_deploy_key = undef,
  String $python_version = '3.5',
){
  include ::apt
  include ::fail2ban
  include ::git
  include ::python

  Exec {
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  user { 'cloudfail2ban':
    ensure         => 'present',
    home           => $home,
    managehome     => true,
    password       => '!',
    purge_ssh_keys => true,
    system         => true,
    shell          => '/bin/false',
  }

  file { 'cloudfail2ban sudoers':
    ensure  => file,
    path    => '/etc/sudoers.d/cloud_fail2ban',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => join([
      'cloudfail2ban ALL=(root) NOPASSWD: /usr/bin/fail2ban-client',
      ''], "\n"),
  }

  $ssh_dir = "${home}/.ssh"
  $ssh_known_hosts = "${ssh_dir}/known_hosts"

  $venv_dir = "${home}/env"

  file { $ssh_dir:
    ensure => directory,
    owner  => 'cloudfail2ban',
    mode   => '0775',
  }

  if $git_deploy_key{
    $ssh_key = "${ssh_dir}/id_rsa"

    file { $ssh_key:
      ensure  => file,
      owner   => 'cloudfail2ban',
      mode    => '0600',
      content => $git_deploy_key,
      before  => Exec['Clone cloud_fail2ban repo'],
    }
  }

  file { $ssh_known_hosts:
    ensure => file,
    owner  => 'cloudfail2ban',
    mode   => '0600',
  }

  file_line { 'cloud_fail2ban github_host_key':
    path => $ssh_known_hosts,
    # lint:ignore:80chars lint:ignore:140chars
    line => 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
    # lint:endignore
  }

  exec { 'Clone cloud_fail2ban repo':
    command => "git clone '${git_repo}' cloud_fail2ban",
    unless  => '[ -d cloud_fail2ban/.git ]',
    cwd     => $home,
    user    => 'cloudfail2ban',
    require => [Class['git'], File[$ssh_known_hosts]],
  }

  exec { 'Update cloud_fail2ban repo':
    # lint:ignore:80chars lint:ignore:140chars
    command => "bash -c 'git clean -dfx && git checkout \"${git_branch}\" && git reset --hard \"origin/${git_branch}\" && git clean -dfx'",
    unless  => "bash -c 'git fetch && git status | grep \"On branch ${git_branch}\" && git status | grep \"Your branch is up-to-date with \"'",
    # lint:endignore
    cwd     => "${home}/cloud_fail2ban",
    user    => 'cloudfail2ban',
    require => Exec['Clone cloud_fail2ban repo'],
  }

  $venv_version = split($python_version, '[.]')[0]

  python::pyvenv { $venv_dir:
    ensure  => present,
    version => $python_version,
    owner   => 'cloudfail2ban',
    require => [Exec['apt_update'], Package["python${venv_version}-venv"]],
  }

  exec { 'Install Cloud_Fail2Ban':
    command     => "bash -c 'source ${venv_dir}/bin/activate; pip install \"${home}/cloud_fail2ban\" --upgrade'",
    cwd         => $home,
    refreshonly => true,
    user        => 'cloudfail2ban',
    subscribe   => [Exec['Clone cloud_fail2ban repo'], Exec['Update cloud_fail2ban repo'],
                    Python::Pyvenv[$venv_dir]],
  }

  Exec['apt_update'] -> Class['python']
}
