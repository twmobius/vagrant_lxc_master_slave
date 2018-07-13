# Resource for a FireHOL Interface
#
# @param interface Name of the interface, e.g. eth0. Taken from title of the resource.
# @param interface_name Optional name to give the interface, like 'LAN'. Defaults to Interface name.
# @param config_file String param, which config file to work with. Defaults to '/etc/firehol/firehol.con'.
# @param policy Which policy should be applied by default. Defaults to 'drop'. Accepted values: drop, reject, accept
define firehol::dnat4 (
  String                           $backend,
  String                           $interface,
  String                           $matches,
  String                           $config_file    = '/etc/firehol/firehol.conf',
) {

  concat::fragment { "dnat4_${title}":
    target  => $config_file,
    content => template('firehol/firehol_dnat4.erb'),
    order   => '02',
  }
}
