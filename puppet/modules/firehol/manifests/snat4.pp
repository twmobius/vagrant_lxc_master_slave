# Resource for a FireHOL Interface
#
# @param to
# @param src
# @param config_file String param, which config file to work with. Defaults to '/etc/firehol/firehol.con'.
define firehol::snat4 (
  String                           $to,
  String                           $src,
  String                           $config_file    = '/etc/firehol/firehol.conf',
) {
  concat::fragment { "snat4_${title}":
    target  => $config_file,
    content => template('firehol/firehol_snat4.erb'),
    order   => '02',
  }
}
