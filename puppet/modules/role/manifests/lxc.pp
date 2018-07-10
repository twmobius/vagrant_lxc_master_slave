# Role lxc
class role::lxc (
    $public_interface = 'enp0s3',
    $private_interface = 'enp0s8',
    $lxc_bridge = 'br0',
    $bridge_ip = '192.168.1.1',
    $bridge_netmask = '24',
    $lxc_path = '/var/lib/lxc',
    $master = false,
    $rsync_master = undef,
    $rsync_allow = undef,
){

    # Network configuration
    class { 'netplan':
        config_file   => '/etc/netplan/01-custom.yaml',
        ethernets     => {
            $private_interface => {
                'dhcp4' => false,
            },
        },
        bridges       => {
            $lxc_bridge => {
                'addresses'  => ["${bridge_ip}/${bridge_netmask}"],
                'interfaces' => [$private_interface],
            },
        },
        netplan_apply => true,
    }

    # Firewalling host configuration
    class { 'firehol':
        ensure => true,
    }
    firehol::dnat4 { 'http':
        interface => $public_interface,
        backend   => '10.1.1.20',
        matches   => 'proto tcp dport "80 443"',
    }
    firehol::dnat4 { 'vpn-tcp':
        interface => $public_interface,
        backend   => '10.1.1.100',
        matches   => 'proto tcp dport 1194',
    }
    firehol::dnat4 { 'vpn-udp':
        interface => $public_interface,
        backend   => '10.1.1.100',
        matches   => 'proto udp dport 1194',
    }
    firehol::dnat4 { 'mail':
        interface => $public_interface,
        backend   => '10.1.1.110',
        matches   => 'proto tcp dport "25 465 110 143 993 995 587"',
    }
    firehol::dnat4 { 'ftp':
        interface => $public_interface,
        backend   => '10.1.1.20',
        matches   => 'proto tcp dport "20 21"',
    }
    firehol::interface { $public_interface: interface_name => 'public', }
    firehol::interface { $lxc_bridge: interface_name => 'private', }
    firehol::router { 'lxc_router':
        inface  => $lxc_bridge,
        outface => $public_interface,
    }
    firehol::service { 'ssh': server => 'tcp/22,2222', }
    firehol::service { 'mysql': server => 'tcp/3306', }
    firehol::service { 'mail': server => 'tcp/25,465,110,143,993,995', }
    firehol::service { 'web': server => 'tcp/80,443', }
    firehol::service { 'dns': server => 'tcp/53,udp/53', }
    firehol::service { 'openvpn': server => 'tcp/1194,udp/1194', }
    firehol::service { 'ftp': server => 'tcp/20,21', }
    firehol::service { 'rsync': server => 'tcp/873', }

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

    if $rsync_allow {
        firehol::rule { 'rsync-allow':
            interface => $lxc_bridge,
            direction => 'server',
            service   => 'rsync',
            src       => $rsync_allow,
        }
    }


    class { 'rsync::server':
        use_xinetd => false,
    }
    # LXC configuration, dependent on master/slave
    class { 'lxc':
        lxc_networking_device_link    => $lxc_bridge,
        lxc_networking_type           => 'veth',
        lxc_networking_flags          => 'up',
        lxc_networking_nat_enable     => false,
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
        require                       => Class['netplan'],
    }

    file { $lxc_path:
        mode    => 'o+x',
        require => Class['lxc'],
    }

    $lxc_defaults = {
        ensure          => 'present',
        template        => 'download',
        template_options => [
            '--dist', 'ubuntu',
            '--release', 'bionic',
            '--arch', 'amd64',
        ],
        storage_backend => 'dir',
    }
    # Run the containers on the master except a few that only run on the slave
    $master_container_state = $master ? {
        true    => 'running',
        false   => 'stopped',
        default => 'stopped',
    }
    $slave_container_state = $master ? {
        false   => 'running',
        true    => 'stopped',
        default => 'stopped',
    }
    $container_autostart = $master
    $lxcs = {
        'db-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 100000 4999', 'g 0 100000 4999']], },
        'db-2' => { state => $slave_container_state, autostart => !$container_autostart, idmap => [['u 0 105000 4999', 'g 0 105000 4999']], },
        'web-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 110000 4999', 'g 0 110000 4999']], },
        'web-2' => { state => $slave_container_state, autostart => !$container_autostart, idmap => [['u 0 115000 4999', 'g 0 110000 4999']], },
        'adman' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 120000 4999', 'g 0 120000 4999']], },
        'dns-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 125000 4999', 'g 0 120000 4999']], },
        'queue-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 130000 4999', 'g 0 130000 4999']], },
        'search-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 135000 4999', 'g 0 130000 4999']], },
        'live-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 140000 4999', 'g 0 140000 4999']], },
        #'logs-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 145000 4999', 'g 0 145000 4999']], },
        'redis-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 150000 4999', 'g 0 150000 4999']], },
        'vpn-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 155000 4999', 'g 0 155000 4999']], },
        'mail-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 160000 4999', 'g 0 160000 4999']], },
        'nginx-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 165000 4999', 'g 0 165000 4999']], },
        #'zabbix-1' => { state => $master_container_state, autostart => $container_autostart, idmap => [['u 0 170000 4999', 'g 0 170000 4999']], },
    }
    create_resources(lxc, $lxcs, $lxc_defaults)

    # Only define the interface of the lxcs on the master the slave is going to copy them as is
    if $master {
        $lxc_interface_defaults = {
            device_name  => 'eth0',
            ipv4_gateway => $bridge_ip,
            ensure       => present,
            index        => 0,
            link         => $lxc_bridge,
            type         => 'veth',
            restart      => true,
        }
        $lxc_interfaces = {
            'db-1' => { container => 'db-1', ipv4 => ['10.1.1.10/24'], },
            'db-2' => { container => 'db-2', ipv4 => ['10.1.1.11/24'], },
            'web-1' => { container => 'web-1', ipv4 => ['10.1.1.20/24'], },
            'web-2' => { container => 'web-2', ipv4 => ['10.1.1.21/24'], },
            'adman' => { container => 'adman', ipv4 => ['10.1.1.30/24'], },
            'queue-1' => { container => 'queue-1', ipv4 => ['10.1.1.40/24'], },
            'search-1' => { container => 'search-1', ipv4 => ['10.1.1.50/24'], },
            'live-1' => { container => 'live-1', ipv4 => ['10.1.1.60/24'], },
            #'logs-1' => { container => 'logs-1', ipv4 => ['10.1.1.70/24'], },
            'redis-1' => { container => 'redis-1', ipv4 => ['10.1.1.80/24'], },
            'dns-1' => { container => 'dns-1', ipv4 => ['10.1.1.90/24'], },
            'vpn-1'  => { container => 'vpn-1', ipv4 => ['10.1.1.100/24'], },
            'mail-1' => { container => 'mail-1', ipv4 => ['10.1.1.110/24'], },
            'nginx-1' => { container => 'nginx-1', ipv4 => ['10.1.1.120/24'], },
            # 'zabbix-1' => { container => 'redis-1', type => 'none' }, # On the host namespace
        }
        create_resources(lxc_interface, $lxc_interfaces, $lxc_interface_defaults)
    }

    # To be excluded because they are started on the slave
    # Rsync configuration, dependent on master/slave
    if $master {
        rsync::server::module { 'lxc':
            path => $lxc_path,
            uid  => 0,
            gid  => 0,
        }
    } elsif $rsync_master {
        $t = $lxcs.filter |$k, $v| { $v['state'] == 'running' }
        $excluded = $t.map |$k, $v| { "${lxc_path}/${k}" }
        rsync::get { 'lxc':
            source  => "rsync://${rsync_master}/lxc/",
            purge   => true,
            exclude => $excluded,
            path    => $lxc_path,
        }
        $t2 = $excluded.map |$value| { "--exclude ${value}" }
        $cron_excluded = join($t2, ' ')
        cron { 'rsync-lxc':
            command => "/usr/bin/rsync -axHAX --delete ${cron_excluded} rsync://${rsync_master}/lxc/ ${lxc_path} >/dev/null 2>&1",
            user    => 'root',
            minute  => '*/10',
        }
    } # Otherwise we are neither master, nor slave
}
