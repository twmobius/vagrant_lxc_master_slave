# Resource for a FireHOL router
#
# @param router Name of the router, e.g. myrouter. Taken from title of the resource.
# @param inface The interface requests come from
# @param outface The interface requests going out of
# @param policy Which policy should be applied by default. Defaults to 'drop'. Accepted values: drop, reject, accept
define firehol::router (
  String                           $inface,
  String                           $outface,
  String                           $router      = $title,
  String                           $config_file    = '/etc/firehol/firehol.conf',
) {

  concat::fragment { "router_${router}":
    target  => $config_file,
    content => template('firehol/firehol_router.erb'),
    order   => "${router}-0",
  }
}
