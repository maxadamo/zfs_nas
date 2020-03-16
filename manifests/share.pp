# == Class: zfs_nas::share
#
#
define zfs_nas::share (
  $ensure,
  $client_list,
  $nodes_hostnames,
  $share_name = $name,
) {

  $client_string = join($client_list, ',')
  $peer_host = delete($nodes_hostnames, $facts['fqdn'])

  zfs { "zfs_nas/${share_name}":
    ensure     => $ensure,
    mountpoint => "/zfs_nas/${share_name}",
    sharenfs   => $client_string,
    require    => Class['nfs'];
  }

  monit::check { "syncoid_${share_name}":
    content => "check program storagesync with path /usr/local/bin/run_storagesync_${share_name}.sh
    every 1 cycles 
    if status != 0 then alert\n";
  }

  file { "/usr/local/bin/syncoid_${share_name}.sh":
    ensure  => present,
    content => "PATH=\"/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\"
ip add sh | grep -q secondary && exit 0
flock /tmp/syncoid_${share_name} syncoid root@${peer_host}:zfs_nas/${share_name} zfs_nas/${share_name}\n";
  }

}
