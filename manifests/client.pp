# == Define: zfs_nas::client
#
# === Parameters & Variables
#
# [*server*] <String>
#            Server VIP
#
# [*share*] <String>
#           shared folder on the server
#
# [*ensure*] <Bool>
#   default: present (valid values: present and absent)
#
# [*mount_point*] <String>
#   default: $name (mount point)
#
# [*nfs_server_enabled*] <Bool>
#   default: false (whether nfs server should be enabled or not)
#
# [*manage_firewall*] <Bool>
#   default: true (manage iptables on the client)
#
# [*ipv6_enabled*] <Bool>
#   default: true (enable ipv6)
#
# [*options_nfs*] <String>
#   default: 'tcp,soft,nolock,rsize=32768,wsize=32768,intr,noatime,actimeo=3'
#            NFS client options
#
define zfs_nas::client (
  $server,
  $share,
  $ensure             = present,
  $mount_point        = $name,
  $nfs_server_enabled = false,
  $manage_firewall    = true,
  $ipv6_enabled       = true,
  $options_nfs        = 'tcp,soft,nolock,rsize=32768,wsize=32768,intr,noatime,actimeo=3',
) {

  if any2bool($manage_firewall) == true {
    unless defined(Class['::tiny_nas::client::firewall']) {
      class { '::tiny_nas::client::firewall':
        ipv6_enabled => $ipv6_enabled;
      }
    }
  }

  if $ensure == present {
    $client_ensure = present
  } elsif $ensure == absent {
    $client_ensure = absent
  } else {
    fail("ensure can only be 'present' or 'absent'")
  }

  $stripped_mount_point = regsubst($mount_point, '/', '_', 'G')
  $script_name = "/usr/local/sbin/fix_stale_mount${stripped_mount_point}.sh"

  tiny_nas::client::client { $mount_point:
    ensure               => $client_ensure,
    stripped_mount_point => $stripped_mount_point,
    script_name          => $script_name,
    nfs_server_enabled   => $nfs_server_enabled,
    server               => $server,
    share                => $share,
    options_nfs          => $options_nfs;
  }

}
