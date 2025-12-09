# Application Gateway Terraform Examples

This directory contains example configurations for deploying Azure Application Gateway with SAS Viya4 on AKS.

## Quick Reference

| Scenario | Use Case | WAF | Identity | Key Vault | Configuration |
|----------|----------|-----|----------|-----------|--------------|
| **Scenario 1** | Dev/Test | ❌ No | ❌ No | ❌ No | File-based certs |
| **Scenario 2** | Production | ✅ Auto | ✅ Auto | ✅ Yes | Key Vault (Recommended) |
| **Scenario 3** | Enterprise | ✅ Custom | ✅ Existing | ✅ Yes | Existing resources |

## Configuration in Main Terraform File

Application Gateway is configured in your main `terraform.tfvars` file alongside your AKS cluster configuration. The module uses the `prefix` variable to automatically name resources.

### Minimal Configuration (Development)

```hcl
# In your main terraform.tfvars file

prefix   = "viya4dev"
location = "eastus"

# Networking (prefix automatically applied)
# Creates: viya4dev-vnet, viya4dev-appgw-subnet, etc.

# Application Gateway - Simple setup
create_app_gateway = true
enable_waf         = false  # No WAF for dev

app_gateway_config = {
  backend_address_pool_fqdn = ["${prefix}-ingress-lb.eastus.cloudapp.azure.com"]
  
  ssl_certificate = [{
    name     = "dev-cert"
    data     = "./certs/dev-certificate.pfx"
    password = "DevCertPassword123!"
  }]
}

# AKS and other configs...
kubernetes_version = "1.26"
# ...existing code...
```

**What gets created:**
- ✅ `{prefix}-appgw` - Application Gateway (Standard_v2)
- ✅ `{prefix}-appgw-pip` - Public IP
- ✅ Smart defaults for listeners, rules, probes

---

### Production Configuration (Recommended)

```hcl
# In your main terraform.tfvars file

prefix   = "viya4prod"
location = "eastus"

# Application Gateway - Production with WAF and Key Vault
create_app_gateway = true
enable_waf         = true  # Default, can be omitted

# Key Vault for certificates (auto-creates identity and grants access)
key_vault_name = "prod-keyvault"
subnet_name    = "appgw-subnet"
vnet_name      = "prod-vnet"

app_gateway_config = {
  backend_address_pool_fqdn = ["prod-ingress.example.com"]
  
  # Certificates from Key Vault
  ssl_certificate = [{
    name                = "wildcard-cert"
    key_vault_secret_id = "https://prod-keyvault.vault.azure.net/secrets/wildcard-cert/latest"
  }]
  
  # Backend trust certificate
  backend_trusted_root_certificate = [{
    name                = "backend-ca"
    key_vault_secret_id = "https://prod-keyvault.vault.azure.net/secrets/backend-ca/latest"
  }]
  
  backend_host_name = "backend.example.com"
}

# Postgres and other configs...
postgres_servers = {
  default = {}
}

# AKS config...
kubernetes_version         = "1.26"
default_nodepool_min_nodes = 2
# ...existing code...
```

**What gets created automatically:**
- ✅ `{prefix}-appgw` - Application Gateway (WAF_v2)
- ✅ `{prefix}-appgw-pip` - Public IP
- ✅ `{prefix}-appgw-identity` - User-assigned identity
- ✅ `{prefix}-appgw-waf-policy` - WAF policy (OWASP 3.2, Prevention)
- ✅ Key Vault access policy for identity
- ✅ HTTPS listener, routing rule, health probe

---

### Enterprise Configuration (Existing Resources)

```hcl
# In your main terraform.tfvars file

prefix   = "viya4ent"
location = "eastus2"

# Application Gateway - Use existing resources
create_app_gateway = true
enable_waf         = true
create_identity    = false  # Use existing

# Reference existing resources by name (not full IDs)
subnet_name         = "appgw-subnet"
vnet_name           = "enterprise-vnet"
identity_name       = "shared-appgw-identity"
waf_policy_name     = "custom-waf-policy"
public_ip_name      = "existing-appgw-pip"
key_vault_name      = "enterprise-keyvault"

# Don't create new public IP
create_public_ip = false

app_gateway_config = {
  backend_address_pool_fqdn = ["enterprise-ingress.example.com"]
  
  ssl_certificate = [{
    name                = "enterprise-cert"
    key_vault_secret_id = "https://enterprise-keyvault.vault.azure.net/secrets/cert/v1"
  }]
  
  backend_trusted_root_certificate = [{
    name                = "enterprise-ca"
    key_vault_secret_id = "https://enterprise-keyvault.vault.azure.net/secrets/ca/v1"
  }]
  
  backend_host_name = "enterprise-backend.example.com"
}

# ...existing code...
```

---

## Resource Naming Convention

All resources are automatically named using your `prefix`:

| Resource Type | Naming Pattern | Example (prefix="viya4prod") |
|--------------|----------------|------------------------------|
| Application Gateway | `{prefix}-appgw` | `viya4prod-appgw` |
| Public IP | `{prefix}-appgw-pip` | `viya4prod-appgw-pip` |
| User Identity | `{prefix}-appgw-identity` | `viya4prod-appgw-identity` |
| WAF Policy | `{prefix}-appgw-waf-policy` | `viya4prod-appgw-waf-policy` |
| Backend Pool | `{prefix}-appgw-backend-pool` | `viya4prod-appgw-backend-pool` |
| Listener | `{prefix}-appgw-https-listener` | `viya4prod-appgw-https-listener` |

---

## Smart Defaults

### What You Must Provide

**Minimum required:**
```hcl
create_app_gateway = true

app_gateway_config = {
  backend_address_pool_fqdn = ["your-ingress-lb-hostname"]
  
  ssl_certificate = [{
    name                = "cert-name"
    key_vault_secret_id = "https://vault.azure.net/secrets/cert"
    # OR for file-based:
    # data     = "./certs/cert.pfx"
    # password = "password"
  }]
}
```

### What Gets Auto-Created

If you don't specify these, the module creates intelligent defaults:

| Component | Default Behavior |
|-----------|-----------------|
| **Subnet** | Uses `{prefix}-appgw-subnet` from `{prefix}-vnet` |
| **Public IP** | Creates `{prefix}-appgw-pip` (Static, Standard) |
| **Identity** | Auto-created when Key Vault certs are used |
| **WAF Policy** | Created with OWASP 3.2, Prevention mode |
| **Frontend Ports** | 443 (HTTPS), 80 (HTTP) |
| **Listeners** | HTTPS listener using first certificate |
| **Routing Rules** | Basic rule connecting listener to backend |
| **Health Probes** | HTTPS probe to backend (if backend uses HTTPS) |

---

## Integration with AKS Cluster

The Application Gateway is deployed alongside your AKS cluster and configured to route traffic to the ingress controller.

### Complete Example

```hcl
# Complete terraform.tfvars for SAS Viya4 with Application Gateway

prefix   = "viya4prod"
location = "eastus"

# Network and access
default_public_access_cidrs = ["203.0.113.0/24"]
ssh_public_key              = "~/.ssh/id_rsa.pub"

tags = {
  "owner"       = "admin@example.com"
  "environment" = "production"
  "project"     = "viya4"
}

# Application Gateway (routes to AKS ingress)
create_app_gateway = true
enable_waf         = true
key_vault_name     = "prod-keyvault"
subnet_name        = "appgw-subnet"
vnet_name          = "prod-vnet"

app_gateway_config = {
  # Backend is the AKS ingress controller load balancer
  backend_address_pool_fqdn = ["viya4prod-ingress.eastus.cloudapp.azure.com"]
  
  ssl_certificate = [{
    name                = "viya-cert"
    key_vault_secret_id = "https://prod-keyvault.vault.azure.net/secrets/viya-cert"
  }]
  
  backend_trusted_root_certificate = [{
    name                = "backend-ca"
    key_vault_secret_id = "https://prod-keyvault.vault.azure.net/secrets/ca-cert"
  }]
  
  backend_host_name = "viya.example.com"
}

# Postgres Database
postgres_servers = {
  default = {}
}

# AKS Configuration
kubernetes_version         = "1.26"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v4"

# Node Pools
node_pools = {
  cas = {
    machine_type = "Standard_E16s_v3"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 5
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = {
      "workload.sas.com/class" = "cas"
    }
  }
  # ...existing code...
}

# Jump Server
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage
storage_type = "standard"
```

---

## Configuration Options

### WAF Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `enable_waf` | `true` | Enable WAF (automatically uses WAF_v2 SKU) |
| `waf_policy_name` | Auto-created | Use existing custom WAF policy by name |

**WAF Mode:** Always uses **Prevention** mode (secure by default)

### Identity Configuration

| Setting | Behavior |
|---------|----------|
| Not specified | Auto-created when Key Vault certs are used |
| `identity_name = "name"` | Use existing identity |
| `create_identity = false` | Must provide existing identity |

### Certificate Configuration

**Key Vault (Production - Recommended):**
```hcl
ssl_certificate = [{
  name                = "cert-name"
  key_vault_secret_id = "https://vault.azure.net/secrets/cert"
}]
```

**File-based (Development):**
```hcl
ssl_certificate = [{
  name     = "cert-name"
  data     = "./certs/certificate.pfx"
  password = "password"
}]
```

---

## TLS Security (Non-Overridable)

All Application Gateway deployments enforce **SAS Cryptography Standard**:

### Enabled
- ✅ **TLS 1.3** - `TLS_AES_256_GCM_SHA384`, `TLS_AES_128_GCM_SHA256`
- ✅ **TLS 1.2** - `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`, `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256`

### Blocked
- ❌ TLS 1.0, TLS 1.1
- ❌ CBC mode ciphers
- ❌ 3DES (SWEET32)
- ❌ RSA key exchange

**These security settings cannot be modified.**

---

## Troubleshooting

### Issue: "Subnet must be provided"

**Solution:** Specify subnet name:
```hcl
subnet_name = "appgw-subnet"
vnet_name   = "your-vnet"
```

### Issue: "Identity required for Key Vault"

**Solution:** Module auto-creates identity when Key Vault certs are used. If using existing identity:
```hcl
create_identity = false
identity_name   = "existing-identity"
```

### Issue: Backend pool hostname not resolving

**Solution:** Ensure ingress controller is deployed and has a load balancer with public IP:
```bash
kubectl get svc -n ingress-nginx
```

The Application Gateway `backend_address_pool_fqdn` should point to this load balancer's hostname.

---

## Additional Resources

- [Main Module README](../modules/azurerm_application_gateway/README.md)
- [Azure Application Gateway Documentation](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [SAS Viya4 IaC for Azure](../README.md)
