# Class lxc::master
class role::lxc::master (
    $public_interface = 'enp0s3', # TODO actually find this
    $private_interface = 'enp0s8', # TODO Actually find this
    $lxc_bridge = 'br0',
){

    class { 'netplan':
        config_file   => '/etc/netplan/01-custom.yaml',
        ethernets     => {
            $private_interface => {
                'dhcp4' => false,
            },
        },
        bridges       => {
            $lxc_bridge => {
                'addresses'  => ['10.1.1.1/24'],
                'interfaces' => [$private_interface], # TODO: Find the correct interface for
            },
        },
        netplan_apply => true,
    }

    class { 'firehol':
        ensure => true,
    }
    firehol::interface { $public_interface: interface_name => 'public', }
    firehol::interface { $lxc_bridge: interface_name => 'private', }
    firehol::router { 'lxc_router':
        inface  => $lxc_bridge,
        outface => $public_interface,
    }
    firehol::service { 'ssh': server => 'tcp/22', }
    firehol::service { 'mysql': server => 'tcp/3306', }
    firehol::service { 'mail': server => 'tcp/25,110,143,993,995', }
    firehol::service { 'web': server => 'tcp/80,443', }
    firehol::service { 'dns': server => 'tcp/53,udp/53', }
    firehol::service { 'openvpn': server => 'tcp/1194,udp/1194', }
    firehol::service { 'ftp': server => 'tcp/21', }

    firehol::rule { 'public-server':
        interface => $public_interface,
        direction => 'server',
        service   => ['icmp', 'mail', 'ssh', 'web', 'openvpn', 'ftp'],
    }
    firehol::rule { 'public-client':
        interface => $public_interface,
        direction => 'client',
        service   => 'all',
    }
    firehol::rule { 'bridge-server':
        interface => $lxc_bridge,
        direction => 'server',
        service   => ['icmp', 'mail', 'ssh', 'web'],
    }
    firehol::rule { 'bridge-client':
        interface => $lxc_bridge,
        direction => 'client',
        service   => 'all',
    }
    firehol::router_rule { 'masquerade':
        router    => 'lxc_router',
        direction => '',
        action    => 'masquerade',
        service   => '',
    }
    firehol::router_rule { 'route_all':
        router    => 'lxc_router',
        direction => 'route',
        action    => 'accept',
        service   => 'all',
    }

    class { 'rsync::server':
        use_xinetd => false,
    }
    rsync::server::module { 'lxc':
        path => '/var/lib/lxc',
    }

    class { 'lxc':
        lxc_networking_device_link    => $lxc_bridge,
        lxc_networking_type           => 'veth',
        lxc_networking_flags          => 'up',
        lxc_networking_nat_enable     => false,
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
        require                       => Class['netplan'],
    }

    $lxc_defaults = {
        ensure          => 'present',
        template        => 'ubuntu',
        storage_backend => 'dir',
    }
    $lxcs = {
        'db-1' => { state => 'running', autostart => true, },
        'db-2' => { state => 'stopped', autostart => false, },
        'web-1' => { state => 'running', autostart => true, },
        'web-2' => { state => 'stopped', autostart => false, },
        'ad-1' => { state => 'running', autostart => true, },
        'dns-1' => { state => 'running', autostart => true, },
        'queue-1' => { state => 'running', autostart => true, },
        'search-1' => { state => 'running', autostart => true, },
        'live-1' => { state => 'running', autostart => true, },
        'logs-1' => { state => 'running', autostart => true, },
        'vpn-1' => { state => 'running', autostart => true, },
        'mail-1' => { state => 'running', autostart => true, },
        'mc-1' => { state => 'running', autostart => true, },
        'various-1' => { state => 'running', autostart => true, },
        'redis-1' => { state => 'running', autostart => true, },
        'zabbix-1' => { state => 'running', autostart => true, },
    }
    create_resources(lxc, $lxcs, $lxc_defaults)

    $lxc_interface_defaults = {
        device_name => 'eth0',
        ensure      => present,
        index       => 0,
        link        => $lxc_bridge,
        type        => 'veth',
        restart     => true,
    }
    $lxc_interfaces = {
        'db-1' => { container => 'db-1', ipv4 => ['10.1.1.10/24'], },
        'db-2' => { container => 'db-2', ipv4 => ['10.1.1.11/24'], },
        'web-1' => { container => 'web-1', ipv4 => ['10.1.1.20/24'], },
        'web-2' => { container => 'web-2', ipv4 => ['10.1.1.21/24'], },
        'ad-1' => { container => 'ad-1', ipv4 => ['10.1.1.30/24'], },
        'dns-1' => { container => 'dns-1', type => 'none' }, # This is on the host namespace
        'queue-1' => { container => 'queue-1', ipv4 => ['10.1.1.40/24'], },
        'search-1' => { container => 'search-1', ipv4 => ['10.1.1.50/24'], },
        'live-1' => { container => 'live-1', ipv4 => ['10.1.1.60/24'], },
        'logs-1' => { container => 'logs-1', ipv4 => ['10.1.1.70/24'], },
        'vpn-1'  => { container => 'vpn-1', type => 'none' }, # On the host namespace
        'mail-1' => { container => 'mail-1', ipv4 => ['10.1.1.80/24'], },
        'mc-1' => { container => 'mc-1', ipv4 => ['10.1.1.90/24'], },
        'various-1' => { container => 'various-1', ipv4 => ['10.1.1.100/24'], },
        'redis-1' => { container => 'redis-1', ipv4 => ['10.1.1.110/24'], },
        'zabbix-1' => { container => 'redis-1', type => 'none' }, # On the host namespace
    }
    create_resources(lxc_interface, $lxc_interfaces, $lxc_interface_defaults)
}
