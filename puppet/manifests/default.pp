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

$lxcs = {
    'db-1'      => { ipv4 => '10.1.1.10',  on_master => true },
    'db-2'      => { ipv4 => '10.1.1.11',  on_master => false },
    'web-1'     => { ipv4 => '10.1.1.20',  on_master => true },
    'web-2'     => { ipv4 => '10.1.1.21',  on_master => false },
    'adman'     => { ipv4 => '10.1.1.30',  on_master => true },
    'queue-1'   => { ipv4 => '10.1.1.40',  on_master => true },
    'search-1'  => { ipv4 => '10.1.1.50',  on_master => true },
    'live-1'    => { ipv4 => '10.1.1.60',  on_master => true },
    'logs-1'    => { ipv4 => '10.1.1.70',  on_master => false },
    'redis-1'   => { ipv4 => '10.1.1.80',  on_master => true },
    'dns-1'     => { ipv4 => '10.1.1.90',  on_master => true },
    'vpn-1'     => { ipv4 => '10.1.1.100', on_master => true },
    'mail-1'    => { ipv4 => '10.1.1.110', on_master => true },
    'nginx-1'   => { ipv4 => '10.1.1.120', on_master => true },
  # 'zabbix-1'  => { ipv4 => '10.1.1.130', on_master => true },
    'ai-1'          => { ipv4 => '10.1.1.140', on_master => false },
    'workspaces-1'  => { ipv4 => '10.1.1.150', on_master => false },
    'analytics'     => { ipv4 => '10.1.1.160', on_master => false }
}
