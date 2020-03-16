# == Class: zfs_nas::firewall::cluster
#
# WE STILL MISS SYNCOID PORTS
#
class zfs_nas::firewall::cluster (
  $nodes_ip4,
  $nodes_ip6 = []
) {

  $nodes_ips = concat($nodes_ip4, $nodes_ip6)
  $peer_ip = delete($nodes_ip4, $::ipaddress)

  $nodes_ips.each | String $node_ip | {
    if $node_ip =~ Stdlib::IP::Address::V6 { $provider = 'ip6tables' } else { $node_ip = 'iptables' }
    firewall {
      "200 allow inbound UDP to port 111, 892, 2049, 4045 from ${node_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $node_ip,
        provider => $provider,
        proto    => udp,
        dport    => [111, 892, 2049, 4045];
      "200 allow inbound TCP to port 111, 892, 2049, 4045 from ${node_ip} for provider ${provider}":
        chain    => 'INPUT',
        action   => accept,
        source   => $node_ip,
        provider => $provider,
        proto    => tcp,
        dport    => [111, 892, 2049, 4045];
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
