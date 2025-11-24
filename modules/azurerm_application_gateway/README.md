# Azure Application Gateway Module - TLS Security Configuration

## Overview
This module configures Azure Application Gateway with secure TLS settings compliant with the SAS Cryptography Standard.

## TLS Security Configuration

### Enforced Settings
- **Minimum Protocol**: TLS 1.2
- **Cipher Suite**: `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`

### Blocked (Non-Compliant)
- TLS 1.0 and TLS 1.1 (deprecated protocols)
- All CBC mode ciphers (weak encryption)
- 3DES ciphers (SWEET32 vulnerability)
- RSA key exchange ciphers
- AES-128 ciphers

## SAS Cryptography Standard Compliance

This configuration aligns with SAS requirements:
- **Confidentiality**: AES-256
- **Integrity**: SHA-384
- **Key Establishment**: ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)

### Platform Limitations
- Azure Application Gateway uses NIST P-256 curve by default (SAS standard requires P-384)
- TLS 1.3 is not yet supported by Azure Application Gateway
- Ensure SSL certificates use RSA 3072-bit or larger keys

## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ssl_min_protocol_version` | Minimum TLS protocol version | `TLSv1_2` | No |
| `ssl_cipher_suites` | List of approved cipher suites | `["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"]` | No |

## References
- [Azure Application Gateway SSL Policy](https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-ssl-policy-overview)
- SAS Cryptography Standard (Internal)
