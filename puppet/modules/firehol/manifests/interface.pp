# Resource for a FireHOL Interface
#
# @param interface Name of the interface, e.g. eth0. Taken from title of the resource.
# @param interface_name Optional name to give the interface, like 'LAN'. Defaults to Interface name.
# @param config_file String param, which config file to work with. Defaults to '/etc/firehol/firehol.con'.
# @param policy Which policy should be applied by default. Defaults to 'drop'. Accepted values: drop, reject, accept
define firehol::interface (
  String                           $interface      = $title,
  String                           $interface_name = $interface,
  String                           $config_file    = '/etc/firehol/firehol.conf',
  Enum['drop', 'accept', 'reject'] $policy = 'drop',
) {

  concat::fragment { "interface_${interface}":
    target  => $config_file,
    content => template('firehol/firehol_interface.erb'),
    order   => "${interface}-0",
  }

}
