# FireHOL Rule
#
# @param rule_name Name of the Rule. Defaults to $title
# @param router The router this Rule applies to.
# @param service Name of the service this rule applies to.
# @param action What to do with $service. Defaults to 'accept'. Allowed values: accept, reject, drop
# @param direction Which direction to allow $service in. Defaults to server. Allowed values: server, client
# @param config_file String param on which config file to operate on. Defaults to '/etc/firehol/firehol.con'.
# @param v Optional param specifying which IP Version should be allowed. Defaults to 4. Allowed values: 4, 6, 4+6.
define firehol::router_rule (
  String                           $router,
  String                           $rule_name    = $title,
  String                           $config_file  = '/etc/firehol/firehol.conf',
  String                           $direction    = 'route',
  String                           $action       = 'accept',
  Variant[String, Array[String]]   $service      = '',
  Optional[Enum['4', '6', '4+6']]  $v            = '4',
) {

  $all_services = any2array($service)

  if ($v == '4') or ($v == '4+6') {
    concat::fragment { "rule_${router}_${rule_name}":
      target  => $config_file,
      content => template('firehol/firehol_router_rule.erb'),
      order   => "${router}-10-${rule_name}",
    }
  }

  if ($v == '6') or ($v == '4+6') {
    concat::fragment { "rule_${router}_${rule_name}_v6":
      target  => $config_file,
      content => template('firehol/firehol_router_rule6.erb'),
      order   => "${router}-10-${rule_name}-v6",
    }

  }
}
