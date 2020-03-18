# Class: zfs_nas::ssh
#
#
class zfs_nas::ssh ($peer_fqdn, $ssh_id_rsa, $ssh_pub_key) {

  ssh_authorized_key { 'syncoid':
    ensure => present,
    user   => 'root',
    key    => $ssh_pub_key,
    type   => 'ssh-rsa';
  }

  file {
    default:
      ensure  => present,
      mode    => '0600',
      owner   => root,
      group   => root,
      require => Ssh_authorized_key['syncoid'];
    '/root/.ssh/id_rsa':
      content => $ssh_id_rsa.unwrap;
    '/root/.ssh/config':
      content => "Host ${peer_fqdn[0]}\n  StrictHostKeyChecking no\n";
  }

}
