# FireHOL Rule
#
# @param rule_name Name of the Rule. Defaults to $title
# @param interface The Interface this Rule applies to.
# @param service Name of the service this rule applies to.
# @param action What to do with $service. Defaults to 'accept'. Allowed values: accept, reject, drop
# @param direction Which direction to allow $service in. Defaults to server. Allowed values: server, client
# @param src Optional param specifying which source this Rule applies to. Defaults to undef. (Matches all sources)
# @param dst Optional param specifying which destination this Rule applies to. Defaults to undef. (Matches all destinations)
# @param src6 Optional param specifying which source IPv6 this Rule applies to. Defaults to undef. (Matches all sources)
# @param dst6 Optional param specifying which destination IPv6 this Rule applies to. Defaults to undef. (Matches all destinations)
# @param config_file String param on which config file to operate on. Defaults to '/etc/firehol/firehol.con'.
# @param v Optional param specifying which IP Version should be allowed. Defaults to 4. Allowed values: 4, 6, 4+6.
define firehol::rule (
  String                           $rule_name    = $title,
  String                           $interface    = 'eth0',
  Variant[String, Array[String]]   $service      = undef,
  Enum['accept', 'reject', 'drop'] $action       = 'accept',
  Enum['server', 'client']         $direction    = 'server',
  Optional[String]                 $src          = undef,
  Optional[String]                 $dst          = undef,
  Optional[String]                 $src6         = undef,
  Optional[String]                 $dst6         = undef,
  String                           $config_file  = '/etc/firehol/firehol.conf',
  Optional[Enum['4', '6', '4+6']]  $v            = '4',
) {

  $all_services = any2array($service)

  if ($v == '4') or ($v == '4+6') {
    concat::fragment { "rule_${interface}_${rule_name}":
      target  => $config_file,
      content => template('firehol/firehol_rule.erb'),
      order   => "${interface}-10-${rule_name}",
    }
  }

  if ($v == '6') or ($v == '4+6') {
    concat::fragment { "rule_${interface}_${rule_name}_v6":
      target  => $config_file,
      content => template('firehol/firehol_rule6.erb'),
      order   => "${interface}-10-${rule_name}-v6",
    }

  }
}
