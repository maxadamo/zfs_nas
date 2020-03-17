# == Class: zfs_nas
#
# == based on this post:
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
#
# == Sanoid installation:
#
# there is no Sanoid package available. You need to build the package yourself: 
# https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md
#
# == Params (examples)
#
# - nodes_hostnames:
#   [host1.domain', 'host2.domain']
#
# - nodes_ip4:
#   ['192.168.2.5', '192.168.2.6']
#
# - nodes_ip6:
#   ['2001::....', '2001:....']
#
# - vip_ip4:
#   '192.168.2.7'
#
# - vip_ip6:
#   '2001::....'
#
# - vip_ip4_subnet:
#   24
# - vip_ip6_subnet:
#   64
#
# == Author Massimiliano.adamo <maxadamo@gmail.com>
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
  Variant[Sensitive, String] $ssh_id_rsa,
  String $ssh_pub_key,
  Enum[
    'present', 'absent', 'latest'
  ] $sanoid_ensure                             = present,
  Array  $zfs_package                          = $zfs_nas::params::zfs_package,
  Boolean $manage_sanoid                       = false,
  String $network_interface                    = 'eth0',
  Boolean $manage_firewall                     = true,
  Boolean $manage_repo                         = true,
  Optional[String] $repo_proxy_host            = undef,
  Optional[Integer[1, 65535]] $repo_proxy_port = undef,
  Optional[Array] $mirrors                     = undef, # place holder
) inherits zfs_nas::params {

  if $ssh_id_rsa =~ String {
    notify { '"monitor_password" String detected!':
      message => 'It is advisable to use the Sensitive datatype for "monitor_password"';
    }
    $ssh_id_rsa_wrap = Sensitive($ssh_id_rsa)
  } else {
    $ssh_id_rsa_wrap = $ssh_id_rsa
  }

  if ($manage_repo) {
    if $facts['lsbdistid'] == 'CentOS' {
      class { 'zfs_nas::repositories':
        repo_proxy_host => $repo_proxy_host,
        repo_proxy_port => $repo_proxy_port
      }
    }
  }

  class {
    'zfs_nas::firewall::cluster':
      nodes_ip4 => $nodes_ip4,
      nodes_ip6 => $nodes_ip6;
    'zfs_nas::firewall::nfs':
      zfs_shares => $zfs_shares,
      nodes_ip4  => $nodes_ip4,
      nodes_ip6  => $nodes_ip6;
    'zfs_nas::ssh':
      ssh_id_rsa      => $ssh_id_rsa_wrap,
      ssh_pub_key     => $ssh_pub_key,
      nodes_hostnames => $nodes_hostnames;
    'zfs_nas::config':
      zfs_package   => $zfs_package,
      manage_sanoid => $manage_sanoid,
      sanoid_ensure => $sanoid_ensure;
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
    if has_key($zfs_shares[$share], 'client_list') {
      $client_list = $zfs_shares[$share]['client_list']
    } else {
      fail("${zfs_shares} ${share} is missing a client_list array")
    }
    zfs_nas::share { $share:
      ensure          => $ensure,
      nodes_hostnames => $nodes_hostnames,
      client_list     => $client_list;
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
    class { 'zfs_nas::keepalived':
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
