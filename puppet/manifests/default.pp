if $facts['hostname'] == 'lxc1' {
    class { 'role::lxc':
        public_interface  => 'enp0s3',
        private_interface => 'enp0s8',
        lxc_bridge        => 'br0',
        bridge_ip         => '10.1.1.1',
        bridge_netmask    => '24',
        master            => true,
    }
}
if $facts['hostname'] == 'lxc2' {
    class { 'role::lxc':
        public_interface  => 'enp0s3',
        private_interface => 'enp0s8',
        lxc_bridge        => 'br0',
        bridge_ip         => '10.1.1.2',
        bridge_netmask    => '24',
        master            => false,
        rsync_master      => '10.1.1.1',
    }
}
