node /(host-|lxc)1/ {
    class { 'role::lxc':
        public_interface  => lookup('public_interface', String, 'first', 'enp0s31f6'),
        private_interface => lookup('private_interface', String, 'first', 'enp2s0'),
        lxc_bridge        => 'br0',
        bridge_ip         => '10.1.1.1',
        bridge_netmask    => '24',
        master            => true,
        rsync_allow       => '10.1.1.2',
    }
}

node /(host-|lxc)2/ {
    class { 'role::lxc':
        public_interface  => lookup('public_interface', String, 'first', 'enp0s31f6'),
        private_interface => lookup('private_interface', String, 'first', 'enp2s0'),
        lxc_bridge        => 'br0',
        bridge_ip         => '10.1.1.2',
        bridge_netmask    => '24',
        master            => false,
        rsync_master      => '10.1.1.1',
        rsync_allow       => '10.1.1.1',
    }
}
