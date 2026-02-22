import lumen/net

// ---------- parse_ip_address ---------- //

pub fn parse_ipv4_loopback_test() {
  let assert Ok(net.Ipv4Address(127, 0, 0, 1)) =
    net.parse_ip_address("127.0.0.1")
}

pub fn parse_ipv4_all_zeros_test() {
  let assert Ok(net.Ipv4Address(0, 0, 0, 0)) = net.parse_ip_address("0.0.0.0")
}

pub fn parse_ipv4_all_255_test() {
  let assert Ok(net.Ipv4Address(255, 255, 255, 255)) =
    net.parse_ip_address("255.255.255.255")
}

pub fn parse_ipv4_arbitrary_test() {
  let assert Ok(net.Ipv4Address(192, 168, 1, 100)) =
    net.parse_ip_address("192.168.1.100")
}

pub fn parse_ipv6_loopback_test() {
  let assert Ok(net.Ipv6Address(0, 0, 0, 0, 0, 0, 0, 1)) =
    net.parse_ip_address("::1")
}

pub fn parse_ipv6_all_zeros_test() {
  let assert Ok(net.Ipv6Address(0, 0, 0, 0, 0, 0, 0, 0)) =
    net.parse_ip_address("::")
}

pub fn parse_ipv6_full_test() {
  let assert Ok(net.Ipv6Address(
    0x2001,
    0x0db8,
    0x85a3,
    0x0000,
    0x0000,
    0x8a2e,
    0x0370,
    0x7334,
  )) = net.parse_ip_address("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
}

pub fn parse_ipv6_compressed_test() {
  let assert Ok(net.Ipv6Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)) =
    net.parse_ip_address("fe80::1")
}

pub fn parse_invalid_empty_test() {
  let assert Error(net.Einval) = net.parse_ip_address("")
}

pub fn parse_invalid_garbage_test() {
  let assert Error(net.Einval) = net.parse_ip_address("not_an_ip")
}

pub fn parse_invalid_ipv4_out_of_range_test() {
  let assert Error(net.Einval) = net.parse_ip_address("256.0.0.1")
}

pub fn parse_invalid_ipv4_extra_octets_test() {
  let assert Error(net.Einval) = net.parse_ip_address("127.0.0.1.1")
}

// ---------- ip_address_to_string ---------- //

pub fn ipv4_loopback_to_string_test() {
  let assert "127.0.0.1" =
    net.ip_address_to_string(net.Ipv4Address(127, 0, 0, 1))
}

pub fn ipv4_all_zeros_to_string_test() {
  let assert "0.0.0.0" = net.ip_address_to_string(net.Ipv4Address(0, 0, 0, 0))
}

pub fn ipv4_all_255_to_string_test() {
  let assert "255.255.255.255" =
    net.ip_address_to_string(net.Ipv4Address(255, 255, 255, 255))
}

pub fn ipv4_arbitrary_to_string_test() {
  let assert "192.168.1.100" =
    net.ip_address_to_string(net.Ipv4Address(192, 168, 1, 100))
}

pub fn ipv6_loopback_to_string_test() {
  let assert "::1" =
    net.ip_address_to_string(net.Ipv6Address(0, 0, 0, 0, 0, 0, 0, 1))
}

pub fn ipv6_all_zeros_to_string_test() {
  let assert "::" =
    net.ip_address_to_string(net.Ipv6Address(0, 0, 0, 0, 0, 0, 0, 0))
}

pub fn ipv6_full_to_string_test() {
  let assert "2001:db8:85a3::8a2e:370:7334" =
    net.ip_address_to_string(net.Ipv6Address(
      0x2001,
      0x0db8,
      0x85a3,
      0x0000,
      0x0000,
      0x8a2e,
      0x0370,
      0x7334,
    ))
}

pub fn ipv6_link_local_to_string_test() {
  let assert "fe80::1" =
    net.ip_address_to_string(net.Ipv6Address(0xfe80, 0, 0, 0, 0, 0, 0, 1))
}

pub fn roundtrip_ipv4_test() {
  let assert Ok(addr) = net.parse_ip_address("10.0.0.1")
  let assert "10.0.0.1" = net.ip_address_to_string(addr)
}

pub fn roundtrip_ipv6_test() {
  let assert Ok(addr) = net.parse_ip_address("::1")
  let assert "::1" = net.ip_address_to_string(addr)
}
