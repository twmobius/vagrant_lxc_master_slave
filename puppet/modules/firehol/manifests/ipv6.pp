# Resource for a FireHOL Interface
#
# @param config_file String param, which config file to work with. Defaults to '/etc/firehol/firehol.con'.
define firehol::ipv6 (
  String                           $config_file    = '/etc/firehol/firehol.conf',
) {
  concat::fragment { "firehol_ipv6":
    target  => $config_file,
    content => template('firehol/firehol_ipv6.erb'),
    order   => '03',
  }
}
