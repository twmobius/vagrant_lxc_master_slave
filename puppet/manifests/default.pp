if $facts['hostname'] == 'lxc1' {
    include role::lxc::master
}
if $facts['hostname'] == 'lxc2' {
    include role::lxc::slave
}
