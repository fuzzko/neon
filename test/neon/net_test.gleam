import neon/net

pub fn parse_ipv4_loopback_test() {
  let assert Ok(expected) = net.ipv4_address(127, 0, 0, 1)
  let assert Ok(actual) = net.parse_ip_address("127.0.0.1")

  assert expected == actual
}

pub fn parse_ipv4_all_zeros_test() {
  let assert Ok(expected) = net.ipv4_address(0, 0, 0, 0)
  let assert Ok(actual) = net.parse_ip_address("0.0.0.0")

  assert expected == actual
}

pub fn parse_ipv4_all_255_test() {
  let assert Ok(expected) = net.ipv4_address(255, 255, 255, 255)
  let assert Ok(actual) = net.parse_ip_address("255.255.255.255")

  assert expected == actual
}

pub fn parse_ipv4_arbitrary_test() {
  let assert Ok(expected) = net.ipv4_address(192, 168, 1, 100)
  let assert Ok(actual) = net.parse_ip_address("192.168.1.100")

  assert expected == actual
}

pub fn parse_ipv6_loopback_test() {
  let assert Ok(expected) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 1)
  let assert Ok(actual) = net.parse_ip_address("::1")

  assert expected == actual
}

pub fn parse_ipv6_all_zeros_test() {
  let assert Ok(expected) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 0)
  let assert Ok(actual) = net.parse_ip_address("::")

  assert expected == actual
}

pub fn parse_ipv6_full_test() {
  let assert Ok(expected) =
    net.ipv6_address(
      0x2001,
      0x0db8,
      0x85a3,
      0x0000,
      0x0000,
      0x8a2e,
      0x0370,
      0x7334,
    )
  let assert Ok(actual) =
    net.parse_ip_address("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
  assert expected == actual
}

pub fn parse_ipv6_compressed_test() {
  let assert Ok(expected) = net.ipv6_address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
  let assert Ok(actual) = net.parse_ip_address("fe80::1")
  assert expected == actual
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

pub fn ipv4_loopback_to_string_test() {
  let assert Ok(addr) = net.ipv4_address(127, 0, 0, 1)
  let assert "127.0.0.1" = net.ip_address_to_string(addr)
}

pub fn ipv4_all_zeros_to_string_test() {
  let assert Ok(addr) = net.ipv4_address(0, 0, 0, 0)
  let assert "0.0.0.0" = net.ip_address_to_string(addr)
}

pub fn ipv4_all_255_to_string_test() {
  let assert Ok(addr) = net.ipv4_address(255, 255, 255, 255)
  let assert "255.255.255.255" = net.ip_address_to_string(addr)
}

pub fn ipv4_arbitrary_to_string_test() {
  let assert Ok(addr) = net.ipv4_address(192, 168, 1, 100)
  let assert "192.168.1.100" = net.ip_address_to_string(addr)
}

pub fn ipv6_loopback_to_string_test() {
  let assert Ok(addr) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 1)
  let assert "::1" = net.ip_address_to_string(addr)
}

pub fn ipv6_all_zeros_to_string_test() {
  let assert Ok(addr) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 0)
  let assert "::" = net.ip_address_to_string(addr)
}

pub fn ipv6_full_to_string_test() {
  let assert Ok(addr) =
    net.ipv6_address(
      0x2001,
      0x0db8,
      0x85a3,
      0x0000,
      0x0000,
      0x8a2e,
      0x0370,
      0x7334,
    )
  let assert "2001:db8:85a3::8a2e:370:7334" = net.ip_address_to_string(addr)
}

pub fn ipv6_link_local_to_string_test() {
  let assert Ok(addr) = net.ipv6_address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
  let assert "fe80::1" = net.ip_address_to_string(addr)
}

pub fn roundtrip_ipv4_test() {
  let assert Ok(addr) = net.parse_ip_address("10.0.0.1")
  let assert "10.0.0.1" = net.ip_address_to_string(addr)
}

pub fn roundtrip_ipv6_test() {
  let assert Ok(addr) = net.parse_ip_address("::1")
  let assert "::1" = net.ip_address_to_string(addr)
}

pub fn ipv4_address_version_test() {
  let assert Ok(addr) = net.ipv4_address(127, 0, 0, 1)
  let assert net.Ipv4 = net.ip_address_version(addr)
}

pub fn ipv6_address_version_test() {
  let assert Ok(addr) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 1)
  let assert net.Ipv6 = net.ip_address_version(addr)
}
