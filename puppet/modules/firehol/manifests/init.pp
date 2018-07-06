# Install and manage FireHOL
#
# @param ensure Boolean. If true, FireHOL is installed and managed. If false, everything FireHOL related is removed.
# @param config_file Path to the FireHOL config file. Defaults to '/etc/firehol/firehol.conf'.
# @param allow_outgoing Boolean. If true, automatically add a rule allowing all outgoing traffic (v4+v6)
# @param manage_package Boolean. If true, package is installed. Otherwise package is assumed to be installed otherwise.
class firehol (
  Boolean $ensure         = false,
  String  $config_file    = '/etc/firehol/firehol.conf',
  Boolean $allow_outgoing = true,
  Boolean $manage_package = true,
) {

  if $manage_package == true {
    include ::firehol::package
  }

  concat { $config_file:
    require => Package['firehol'],
    notify  => Service['firehol'],
  }

  concat::fragment { 'firehol-header':
    require => Package['firehol'],
    target  => $config_file,
    content => template('firehol/firehol_header.erb'),
    order   => '01',
  }

  file { '/etc/default/firehol':
    ensure  => 'file',
    content => template('firehol/service_default.erb'),
  }

  service { 'firehol':
    ensure  => $ensure,
    require => File['/etc/default/firehol'],
    start   => 'firehol start',
    restart => 'firehol restart',
    stop    => 'firehol stop',
    status  => sprintf('exit %i', bool2num(! $ensure)),
  }

  if $allow_outgoing {
    ::firehol::rule { 'allow all outgoing traffic (default)':
      service     => 'all',
      direction   => 'client',
      config_file => $config_file,
      v           => '4+6',
    }
  }

}
