# == Class: zfs_nas
#
# == temporary note:
#
# https://serverfault.com/a/842740/312669
#
# == Repositories:
#
# repositories are only needed on CentOS.
# The repository and the GPG key are handled through the package provided by zfsonlinux
# if you have yumrepo and it set to purge unmanaged repositories,
# please, set manage_repo to false and create the repository yourself
#
class zfs_nas (
  Array $nodes_hostnames,
  Array $nodes_ip4,
  Optional[Array] $nodes_ip6,
  Stdlib::IP::Address::V4::Nosubnet $vip_ip4,
  Optional[Stdlib::IP::Address::V6::Nosubnet] $vip_ip6,
  Integer[0, 30] $vip_ip4_subnet,
  Optional[Integer[0, 128]] $vip_ip6_subnet,
  Variant[String, Array] $pool_disks,
  Hash $zfs_shares,
  String $network_interface = 'eth0',
  Boolean $manage_firewall = true,
  Boolean $manage_repo = true,
  Optional[String] $repo_proxy_host = undef,
  Optional[Integer[1, 65535]] $repo_proxy_port = undef,
  Optional[Array] $mirrors = undef, # place holder
) inherits zfs_nas::params {

  include zfs_nas::config

  if ($manage_repo) {
    if $facts['lsbdistid'] == 'CentOS' {
      class { 'zfs_nas::repositories':
        repo_proxy_host => $repo_proxy_host,
        repo_proxy_port => $repo_proxy_port
      }
    }
  }

  # we handle only one default pool (I see no reason to make it customizable)
  zpool { 'zfs_nas':
    disk    => $pool_disks,
    require => Exec['modprobe_zfs'];
  }

  keys($zfs_shares).each | $share | {
    # if ensure is not used default is present
    unless has_key($zfs_shares[$share], 'ensure') {
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
