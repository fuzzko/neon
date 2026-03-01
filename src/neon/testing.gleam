import neon/ssl

/// Key algorithm for test certificate generation.
pub opaque type KeyType {
  Rsa(Int)
  Ec(EcCurve)
}

/// Supported EC curves for test certificates.
pub type EcCurve {
  Secp256r1
  Secp384r1
  Secp521r1
}

/// Test certificate data for one side of a connection.
pub type CertData {
  CertData(cert: BitArray, key: ssl.PrivateKey, cacerts: List(BitArray))
}

/// Test certificate data for both server and client.
pub type PkixTestData {
  PkixTestData(server: CertData, client: CertData)
}

/// Creates a key type for RSA with the given bit size.
pub fn rsa(size: Int) -> KeyType {
  Rsa(size)
}

/// Creates a key type for EC with the given named curve.
pub fn ec(curve: EcCurve) -> KeyType {
  Ec(curve)
}

/// Generates test certificate data for the given key type.
///
/// Both server and client certificate chains are generated with the
/// same key type, no intermediate CAs, and a direct root-to-peer chain.
@external(erlang, "neon_ffi", "pkix_test_data")
pub fn pkix_test_data(key_type: KeyType) -> PkixTestData
