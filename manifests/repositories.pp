# Class: zfs_nas::repositories
#
#
class zfs_nas::repositories (
  $repo_proxy_host = undef,
  $repo_proxy_port = undef
) {

  if ($repo_proxy_host) and ($repo_proxy_port) {
    $proxy_settings = ['--httpproxy', $repo_proxy_host, '--httpport', String($repo_proxy_port)]
  } elsif ($repo_proxy_host) and !($repo_proxy_port) {
    fail('you have set $repo_proxy_host without setting $proxy_port')
  } elsif ($repo_proxy_host) and !($repo_proxy_port) {
    fail('you have set $proxy_port without setting $repo_proxy_host')
  } else {
    $proxy_settings = undef
  }

  $os_major = $facts['os']['distro']['release']['major']
  $os_minor = $facts['os']['distro']['release']['minor']

  if $os_major == '6' {
    $zfs_url = 'http://download.zfsonlinux.org/epel/zfs-release.el6.noarch.rpm'
  } elsif $os_major == '7' or $os_major == '8' {
    $zfs_url = "http://download.zfsonlinux.org/epel/zfs-release.el${os_major}_${os_minor}.noarch.rpm"
  } else {
    fail("${facts['lsbdistid']} ${os_major}.${os_minor} is not supported")
  }

  package { 'zfs-release':
    ensure          => present,
    provider        => 'rpm',
    install_options => $proxy_settings,
    source          => $zfs_url,
  }

}
