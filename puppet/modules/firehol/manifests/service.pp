# Resource to add additional firehol services
#
# @param service_name Name of the firehol service. Defaults to $title
# @param server Server line of the service. Defaults to ''.
# @param client Client line of the service. Defaults to 'default'.
# @param config_file Config file to use. Defaults to /etc/firehol/firehol.conf
define firehol::service (
  String $service_name = $title,
  String $server       = '',
  String $client       = 'default',
  String $config_file  = '/etc/firehol/firehol.conf',
) {

  concat::fragment { "service_${service_name}":
    target  => $config_file,
    content => template('firehol/firehol_service.erb'),
    order   => 010,
  }

}
