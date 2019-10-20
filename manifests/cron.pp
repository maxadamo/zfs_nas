# Class: zfs_nas::cron
#
# */5 * * * * root /sbin/zfs-auto-snapshot -q -g --label=frequent --keep=24 //
# 00 * * * * root /sbin/zfs-auto-snapshot -q -g --label=hourly --keep=24 //
# 59 23 * * * root /sbin/zfs-auto-snapshot -q -g --label=daily --keep=14 //
# 59 23 * * 0 root /sbin/zfs-auto-snapshot -q -g --label=weekly --keep=4 //
# 00 00 1 * * root /sbin/zfs-auto-snapshot -q -g --label=monthly --keep=4 //
#
class zfs_nas::cron ($vip_ip4) {

  cron {
    default:
      ensure => present,
      user   => root;
    "${module_name}_frequent":
      minute  => '*/5',
      command => "ip add sh | grep ${vip_ip4} && /sbin/zfs-auto-snapshot -q -g --label=frequent --keep=24 //";
    "${module_name}_hourly":
      minute  => fqdn_rand(60),
      command => "ip add sh | grep ${vip_ip4} && /sbin/zfs-auto-snapshot -q -g --label=hourly --keep=24 //";
    "${module_name}_daily":
      minute  => fqdn_rand(60),
      hour    => '23',
      command => "ip add sh | grep ${vip_ip4} && /sbin/zfs-auto-snapshot -q -g --label=daily --keep=24 //";
    "${module_name}_weekly":
      minute  => fqdn_rand(60),
      hour    => '23',
      weekday => fqdn_rand(7),
      command => "ip add sh | grep ${vip_ip4} && /sbin/zfs-auto-snapshot -q -g --label=weekly --keep=24 //";
    "${module_name}_monthly":
      minute   => fqdn_rand(60),
      hour     => '23',
      monthday => fqdn_rand(28),
      command  => "ip add sh | grep ${vip_ip4} && /sbin/zfs-auto-snapshot -q -g --label=monthly --keep=24 //";
  }

}
