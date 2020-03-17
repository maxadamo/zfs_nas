# == Define: zfs_nas::client::client
#
define zfs_nas::client::client (
  $ensure,
  $nfs_server_enabled,
  $stripped_mount_point,
  $options_nfs,
  $script_name,
  $server,
  $share,
  $mount_point = $name,
) {

  if $caller_module_name != $module_name {
    fail("this define is intended to be called only within ${module_name}")
  }

  file { $script_name:
    ensure  => $ensure,
    owner   => root,
    group   => root,
    mode    => '0754',
    content => epp("${module_name}/fix_stale_mount.sh.epp", {
      mount_point => $mount_point,
      server      => $server
    });
  }

  monit::check { $stripped_mount_point:
    content => "check program ${stripped_mount_point} with path \"/usr/bin/flock /tmp/syncoid_${stripped_mount_point} ${script_name}\"
    every 1 cycles
    if status != 0 then alert\n";
  }

  unless defined(Class['nfs']) {
    class { 'nfs':
      server_enabled => $nfs_server_enabled,
      client_enabled => true;
    }
  }

  nfs::client::mount { $mount_point:
    ensure      => $ensure,
    server      => $server,
    share       => $share,
    options_nfs => $options_nfs,
    require     => Class['::nfs'];
  }

}
