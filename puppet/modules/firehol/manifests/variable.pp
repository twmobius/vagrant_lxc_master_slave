# Resource for a FireHOL Interface
#
# @param variable Name of the variable, e.g. FIREHOL_ENABLE_SPINNER.
# @param value The value of the variable
# @param config_file String param, which config file to work with. Defaults to '/etc/firehol/firehol.con'.
define firehol::variable (
  String                           $variable,
  String                           $value,
  String                           $config_file    = '/etc/firehol/firehol.conf',
) {
  concat::fragment { "variable_${variable}":
    target  => $config_file,
    content => template('firehol/firehol_variable.erb'),
    order   => '01',
  }
}
