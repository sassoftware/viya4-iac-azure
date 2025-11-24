variable "ssl_min_protocol_version" {
  description = "Minimum TLS protocol version for Application Gateway. Must be TLSv1_2 or higher to comply with SAS Cryptography Standard and block deprecated TLS 1.0/1.1 protocols."
  type        = string
  default     = "TLSv1_2"
  
  validation {
    condition     = contains(["TLSv1_2", "TLSv1_3"], var.ssl_min_protocol_version)
    error_message = "The ssl_min_protocol_version must be TLSv1_2 or TLSv1_3 for security compliance."
  }
}

variable "ssl_cipher_suites" {
  description = <<-EOT
    List of approved SSL cipher suites per SAS Cryptography Standard.
    Only ciphers using AES-256-GCM with SHA-384 are compliant.
    This configuration blocks:
    - Deprecated TLS 1.0/1.1 protocols
    - Weak CBC mode ciphers
    - 3DES ciphers (vulnerable to SWEET32)
    - RSA key exchange ciphers
    Reference: SAS Cryptography Standard requires AES-256, SHA-384
  EOT
  type        = list(string)
  default = [
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
  ]
}