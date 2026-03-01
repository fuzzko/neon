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

// ---------- port validation ---------- //

pub fn port_negative_test() {
  let assert Error(Nil) = net.port(-1)
}

pub fn port_too_large_test() {
  let assert Error(Nil) = net.port(65_536)
}

pub fn port_max_boundary_test() {
  let assert Ok(port) = net.port(65_535)
  let assert 65_535 = net.port_to_int(port)
}

pub fn port_zero_test() {
  let assert Ok(port) = net.port(0)
  let assert 0 = net.port_to_int(port)
}

// ---------- timeout validation ---------- //

pub fn timeout_negative_test() {
  let assert Error(Nil) = net.timeout(-1)
}

pub fn timeout_zero_test() {
  let assert Ok(_) = net.timeout(0)
}

// ---------- ipv4_address validation ---------- //

pub fn ipv4_address_octet_too_large_test() {
  let assert Error(Nil) = net.ipv4_address(256, 0, 0, 0)
}

pub fn ipv4_address_octet_negative_test() {
  let assert Error(Nil) = net.ipv4_address(-1, 0, 0, 0)
}

pub fn ipv4_address_second_octet_too_large_test() {
  let assert Error(Nil) = net.ipv4_address(0, 256, 0, 0)
}

pub fn ipv4_address_third_octet_negative_test() {
  let assert Error(Nil) = net.ipv4_address(0, 0, -1, 0)
}

pub fn ipv4_address_fourth_octet_too_large_test() {
  let assert Error(Nil) = net.ipv4_address(0, 0, 0, 256)
}

// ---------- ipv6_address validation ---------- //

pub fn ipv6_address_group_too_large_test() {
  let assert Error(Nil) = net.ipv6_address(65_536, 0, 0, 0, 0, 0, 0, 0)
}

pub fn ipv6_address_group_negative_test() {
  let assert Error(Nil) = net.ipv6_address(-1, 0, 0, 0, 0, 0, 0, 0)
}

pub fn ipv6_address_last_group_too_large_test() {
  let assert Error(Nil) = net.ipv6_address(0, 0, 0, 0, 0, 0, 0, 65_536)
}

pub fn ipv6_address_middle_group_negative_test() {
  let assert Error(Nil) = net.ipv6_address(0, 0, 0, -1, 0, 0, 0, 0)
}

// ---------- posix_to_string ---------- //

pub fn posix_to_string_econnrefused_test() {
  let assert "econnrefused" = net.posix_to_string(net.Econnrefused)
}

pub fn posix_to_string_eaddrinuse_test() {
  let assert "eaddrinuse" = net.posix_to_string(net.Eaddrinuse)
}

pub fn posix_to_string_eacces_test() {
  let assert "eacces" = net.posix_to_string(net.Eacces)
}

pub fn posix_to_string_nxdomain_test() {
  let assert "nxdomain" = net.posix_to_string(net.Nxdomain)
}
