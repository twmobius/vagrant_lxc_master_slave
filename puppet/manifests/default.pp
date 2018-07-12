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

# XXX DO NOT MESS with the order and/or delete items
$lxcs = {
    'db-1'      => { ipv4 => '10.1.1.10',  subuid_order =>  0, on_master => true },
    'db-2'      => { ipv4 => '10.1.1.11',  subuid_order =>  1, on_master => false },
    'web-1'     => { ipv4 => '10.1.1.20',  subuid_order =>  2, on_master => true },
    'web-2'     => { ipv4 => '10.1.1.21',  subuid_order =>  3, on_master => false },
    'adman'     => { ipv4 => '10.1.1.30',  subuid_order =>  4, on_master => true },
    'queue-1'   => { ipv4 => '10.1.1.40',  subuid_order =>  5, on_master => true },
    'search-1'  => { ipv4 => '10.1.1.50',  subuid_order =>  6, on_master => true },
    'live-1'    => { ipv4 => '10.1.1.60',  subuid_order =>  7, on_master => true },
  # 'logs-1'    => { ipv4 => '10.1.1.70',  subuid_order =>  8, on_master => true },
    'redis-1'   => { ipv4 => '10.1.1.80',  subuid_order =>  9, on_master => true },
    'dns-1'     => { ipv4 => '10.1.1.90',  subuid_order => 10, on_master => true },
    'vpn-1'     => { ipv4 => '10.1.1.100', subuid_order => 11, on_master => true },
    'mail-1'    => { ipv4 => '10.1.1.110', subuid_order => 12, on_master => true },
    'nginx-1'   => { ipv4 => '10.1.1.120', subuid_order => 13, on_master => true },
  # 'zabbix-1'  => { ipv4 => '10.1.1.130', subuid_order => 14, on_master => true },
}
