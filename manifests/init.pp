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
# == Author Massimiliano Adamo <maxadamo@gmail.com>
#
class zfs_nas (
  Array $nodes_hostnames,
  Array $nodes_ip4,
  Optional[Array] $nodes_ip6,
  Stdlib::IP::Address::V4::Nosubnet $vip_ip4,
  Integer[0, 30] $vip_ip4_subnet,
  Variant[String, Array] $pool_disks,
  Hash $zfs_shares,
  Variant[Sensitive, String] $ssh_id_rsa,
  String $ssh_pub_key,
  Optional[Integer[0, 128]] $vip_ip6_subnet            = undef,
  Optional[Stdlib::IP::Address::V6::Nosubnet] $vip_ip6 = undef,
  Enum[
    'present', 'absent', 'latest'
  ] $sanoid_ensure                             = present,
  Boolean $manage_monit                        = true,
  Integer $monit_check_interval                = 15,
  Boolean $manage_sanoid                       = false,
  String $network_interface                    = 'eth0',
  Boolean $manage_firewall                     = true,
  Boolean $manage_repo                         = true,
  Optional[String] $repo_proxy_host            = undef,
  Optional[Integer[1, 65535]] $repo_proxy_port = undef,
  Optional[Array] $mirrors                     = undef, # place holder
) {

  $peer_fqdn = delete($nodes_hostnames, $facts['fqdn'])

  if $ssh_id_rsa =~ String {
    notify { '"monitor_password" String detected!':
      message => 'It is advisable to use the Sensitive datatype for "monitor_password"';
    }
    $ssh_id_rsa_wrap = Sensitive($ssh_id_rsa)
  } else {
    $ssh_id_rsa_wrap = $ssh_id_rsa
  }

  if ($manage_monit) {
    # this is a very basic monit setup
    # you can create you own setup, setting manage_monit to false
    # and adding you parameters of choice
    class { 'monit':
      manage_firewall => false,
      httpd           => true,
      check_interval  => $monit_check_interval,
      httpd_allow     => 'localhost',
      httpd_user      => 'admin',
      httpd_password  => seeded_rand_string(10, $module_name),
      mmonit_password => seeded_rand_string(10, $module_name);
    }
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
      peer_fqdn   => $peer_fqdn,
      ssh_id_rsa  => $ssh_id_rsa_wrap,
      ssh_pub_key => $ssh_pub_key;
    'zfs_nas::config':
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
      ensure      => $ensure,
      peer_fqdn   => $peer_fqdn,
      client_list => $client_list,
      require     => Class['zfs_nas::keepalived'];
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

  class { 'zfs_nas::keepalived':
    network_interface => $network_interface,
    peer_fqdn         => $peer_fqdn,
    nodes_ip4         => $nodes_ip4,
    vip_ip4           => $vip_ip4,
    vip_ip4_subnet    => $vip_ip4_subnet,
    nodes_ip6         => $nodes_ip6,
    vip_ip6           => $vip_ip6,
    zfs_shares        => $zfs_shares,
    vip_ip6_subnet    => $vip_ip6_subnet;
  }

}
