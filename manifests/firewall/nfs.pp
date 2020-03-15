# == Class: zfs_nas::firewall::nfs
#
class zfs_nas::firewall::nfs (
  $sync_dir,
  $nodes_ip4,
  $nodes_ip6 = []
) {

  # create an array with all the clients IPs
  $clients_array = $sync_dir.map |$items, $values| { $values['client_list'] }
  $joined_array = join($clients_array)
  $cleaned_array = regsubst($joined_array, /\((.+?)\)/, 'SEP', 'G')
  $ip_array = split($cleaned_array, 'SEP')

  $nodes_ips = concat($nodes_ip4, $nodes_ip6)
  $peer_ip = delete($nodes_ip4, $::ipaddress)

  $ip_array.each | String $client_ip | {
    if ':' in $client_ip { $provider = 'ip6tables' } else { $provider = 'iptables' }
    firewall {
      "200 allow inbound UDP to port 111, 892, 2049, 4045 from ${client_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $client_ip,
        provider => $provider,
        proto    => udp,
        dport    => [111, 892, 2049, 4045];
      "200 allow inbound TCP to port 111, 892, 2049, 4045 from ${client_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $client_ip,
        provider => $provider,
        proto    => tcp,
        dport    => [111, 892, 2049, 4045];
    }
  }

  $nodes_ips.each | String $node_ip | {
    if ':' in $node_ip { $provider = 'ip6tables' } else { $provider = 'iptables' }
    firewall {
      "200 allow outbound TCP to Csync to ${node_ip} for provider ${provider}":
        chain       => 'OUTPUT',
        action      => accept,
        destination => $node_ip,
        provider    => $provider,
        proto       => tcp,
        dport       => 30865;
      "200 allow inbound TCP to Csync from ${node_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $node_ip,
        provider => $provider,
        proto    => tcp,
        dport    => 30865;
    }
  }

  firewall {
    default:
      action => accept,
      proto  => 'vrrp';
    "200 Allow VRRP inbound from ${peer_ip}":
      chain  => 'INPUT',
      source => $peer_ip;
    '200 Allow VRRP inbound to multicast':
      chain       => 'INPUT',
      destination => '224.0.0.0/8';
    '200 Allow VRRP outbound to multicast':
      chain       => 'OUTPUT',
      destination => '224.0.0.0/8';
    "200 Allow VRRP outbound to ${peer_ip}":
      chain       => 'OUTPUT',
      destination => $peer_ip;
  }

}
# vim:ts=2:sw=2
