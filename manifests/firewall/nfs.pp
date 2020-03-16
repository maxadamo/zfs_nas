# == class: zfs_nas::firewall::nfs
#
class zfs_nas::firewall::nfs (
  $zfs_shares,
  $nodes_ip4,
  $nodes_ip6 = []
) {

  # create an array with all the clients IPs
  $clients_array = $zfs_shares.map |$items, $values| { $values['client_list'] }
  $joined_array = join($clients_array)
  $_cleaned_array = regsubst($joined_array, /\,(.+?)\=@/, 'SEP', 'G')
  $cleaned_array = regsubst($_cleaned_array, /^.*=@|\,.*$/, '', 'G')

  $ip_array = split($cleaned_array, 'SEP')

  $nodes_ips = concat($nodes_ip4, $nodes_ip6)
  $peer_ip = delete($nodes_ip4, $::ipaddress)

  $ip_array.each | String $client_ip | {
    if $client_ip =~ Stdlib::IP::Address::V6 { $provider = 'ip6tables' } else { $provider = 'iptables' }
    firewall {
      "200 allow inbound UDP to port 111, 892, 2049, 4045, 58867 from ${client_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $client_ip,
        provider => $provider,
        proto    => udp,
        dport    => [111, 892, 2049, 4045, 58867];
      "200 allow inbound TCP to port 111, 892, 2049, 4045, 4045, 58867 from ${client_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $client_ip,
        provider => $provider,
        proto    => tcp,
        dport    => [111, 892, 2049, 4045, 58867];
    }
  }

}
# vim:ts=2:sw=2
