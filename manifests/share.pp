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
    mode    => '0755',
    owner   => root,
    group   => root,
    content => epp("${module_name}/syncoid_monit.sh.epp", {
      share_name => $share_name,
      peer_host  => $peer_host
    });
  }

}
