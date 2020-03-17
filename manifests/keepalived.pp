# == Class: zfs_nas::keepalived
#
class zfs_nas::keepalived (
  $network_interface,
  $nodes_hostnames,
  $nodes_ip4,
  $vip_ip4,
  $vip_ip4_subnet,
  $nodes_ip6 = [],
  $vip_ip6 = undef,
  $vip_ip6_subnet = undef,
) inherits zfs_nas::params {

  $keepalived_state = $nodes_ip4[0] ? {
    $::ipaddress => 'MASTER',
    default      => 'BACKUP'
  }
  $keepalived_priority = $nodes_ip4[0] ? {
    $::ipaddress => 200,
    default      => 10
  }

  $peer_ip4 = delete($nodes_ip4, $::ipaddress)
  $_peer_host = delete($nodes_hostnames, [$::hostname, $::fqdn])
  $peer_host = regsubst($_peer_host, ".${::domain}", '')

  include ::keepalived

  keepalived::vrrp::script { 'check_nfs':
    script   => 'killall -0 nfsd',
    interval => 2,
    weight   => 2;
  }

  if ($vip_ip6) {
    $peer_ip6 = delete($nodes_ip6, $::ipaddress6)
    keepalived::vrrp::instance { 'NFS':
      interface                  => $network_interface,
      state                      => $keepalived_state,
      virtual_router_id          => seeded_rand(255, "${module_name}${::environment}") + 0,
      unicast_source_ip          => $::ipaddress,
      unicast_peers              => [$peer_ip4[0]],
      priority                   => $keepalived_priority,
      auth_type                  => 'PASS',
      auth_pass                  => seeded_rand_string(10, "${module_name}${::environment}"),
      virtual_ipaddress          => "${vip_ip4}/${vip_ip4_subnet}",
      virtual_ipaddress_excluded => ["${vip_ip6}/${vip_ip6_subnet}"],
      track_script               => 'check_nfs',
      notify_script_backup       => '/etc/keepalived/keepalived-down.sh',
      notify_script_master       => '/etc/keepalived/keepalived-up.sh';
    }
  } else {
    keepalived::vrrp::instance { 'NFS':
      interface            => $network_interface,
      state                => 'BACKUP',
      virtual_router_id    => seeded_rand(255, "${module_name}${::environment}") + 0,
      unicast_source_ip    => $::ipaddress,
      unicast_peers        => [$peer_ip4[0]],
      priority             => 100,
      auth_type            => 'PASS',
      auth_pass            => seeded_rand_string(10, "${module_name}${::environment}"),
      virtual_ipaddress    => "${vip_ip4}/${vip_ip4_subnet}",
      track_script         => 'check_nfs',
      notify_script_backup => '/etc/keepalived/keepalived-down.sh',
      notify_script_master => '/etc/keepalived/keepalived-up.sh';
    }
  }

  file {
    default:
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0755';
    '/etc/keepalived/keepalived-down.sh':
      source  => "puppet:///modules/${module_name}/keepalived-down.sh";
    '/etc/keepalived/keepalived-up.sh':
      source  => "puppet:///modules/${module_name}/keepalived-up.sh";
  }

}
# vim:ts=2:sw=2
