# == Class: zfs_nas
#
# == temporary note:
#
# https://serverfault.com/a/842740/312669
#
class zfs_nas (
  Array $nodes_hostnames,
  Array $nodes_ip4,
  Optional[Array] $nodes_ip6,
  Stdlib::IP::Address::V4::Nosubnet $vip_ip4,
  Optional[Stdlib::IP::Address::V6::Nosubnet] $vip_ip6,
  Integer[0, 30] $vip_ip4_subnet,
  Optional[Integer[0, 128]] $vip_ip6_subnet,
  Hash $zfs_pools,
  Hash $zfs_shares,
  String $network_interface = 'eth0'
) inherits zfs_nas::params {

  include zfs_nas::config

  keys($zfs_pools).each | $pool | {
    zfs_nas::pool { $pool: pool_disk => $zfs_pools[$pool]['device']; }
  }

  keys($zfs_shares).each | $share | {
    # if ensure is not used default is present
    unless has_key($zfs_shares[$share]['ensure']) {
      $ensure = present
    } else {
      $ensure = $zfs_shares[$share]['ensure']
    }
    # if there is IPv6 and client_list, then client_list must have ipv6
    if $zfs_shares[$share]['client_list'] in $zfs_shares {
      $client_list = $zfs_shares[$share]['client_list']
    } else {
      $client_list = 'on'
    }
    zfs_nas::share { $share:
      ensure      => $ensure,
      zpool_name  => $zfs_shares[$share]['zpool_name'],
      client_list => $client_list;
    }
  }

  if ($nodes_ip6) and !($vip_ip6) {
    fail('$nodes_ip6 is set but $vip_ip6 is not set')
  } elsif ($vip_ip6) and !($vip_ip6) {
    fail('$vip_ip6 is set but $nodes_ip6 is not set')
  } elsif ($vip_ip6) and !($vip_ip6_subnet) {
    fail('$vip_ip6 is set but $vip_ip6_subnet is not set')
  } elsif ($vip_ip6_subnet) and !($vip_ip6) {
    fail('$vip_ip6_subnet is set but $vip_ip6 is not set')
  }
  if ($vip_ip6) {
    class { 'tiny_nas::keepalived':
      network_interface => $network_interface,
      nodes_hostnames   => $nodes_hostnames,
      nodes_ip4         => $nodes_ip4,
      vip_ip4           => $vip_ip4,
      vip_ip4_subnet    => $vip_ip4_subnet,
      nodes_ip6         => $nodes_ip6,
      vip_ip6           => $vip_ip6,
      vip_ip6_subnet    => $vip_ip6_subnet;
    }
  }

}
