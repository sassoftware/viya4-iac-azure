# 🔄 Migration Guide: Secrets → OIDC for default_plan_unit_tests.yml

## ✅ Changes Made

### **Before (Secret-based Auth):**
```yaml
jobs:
  go-tests:
    environment: terraformSecrets
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker Image
        run: docker build ...
      - name: Run Tests
        run: docker run -e TF_VAR_client_secret=$TF_VAR_client_secret ...
        env:
          TF_VAR_client_secret: "${{ secrets.TF_VAR_CLIENT_SECRET }}"
          TF_VAR_client_id: "${{ secrets.TF_VAR_CLIENT_ID }}"
```

### **After (OIDC Auth):**
```yaml
permissions:
  id-token: write  # NEW: Required for OIDC
  contents: read

jobs:
  go-tests:
    environment: terraformSecrets
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login using OIDC  # NEW: Passwordless login
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      
      - name: Build Docker Image
        run: docker build ...
      
      - name: Run Tests with OIDC Auth
        run: |
          docker run \
            -e ARM_USE_OIDC=true \
            -e ARM_USE_CLI=true \
            -v $HOME/.azure:/root/.azure:ro \  # NEW: Mount Azure CLI credentials
            ...
```

---

## 🔑 Key Changes

| Change | Old | New |
|--------|-----|-----|
| **Authentication** | Client Secret | OIDC Token (temporary) |
| **Secrets Used** | 4 secrets | 0 secrets |
| **Variables Used** | 0 | 3 variables |
| **Permissions** | None | `id-token: write` |
| **Azure Login** | Implicit in Docker | Explicit with `azure/login@v2` |
| **Secret Rotation** | Required every 60 days | ❌ Not needed |

---

## 📋 Setup Checklist

### ✅ Step 1: Azure Configuration (One-time)

1. **Go to Azure Portal** → Entra ID → App registrations → **PSCLOUD**

2. **Navigate to:** Certificates & secrets → **Federated credentials** → **Add credential**

3. **Configure:**
   - Scenario: `GitHub Actions deploying Azure resources`
   - Organization: `sassoftware`
   - Repository: `viya4-iac-azure`
   - Entity type: `Environment`
   - Environment name: `terraformSecrets`
   - Name: `github-terraformSecrets-oidc`

4. **Click:** Add

5. **Verify RBAC:**
   - Subscriptions → Your Subscription → IAM
   - Ensure PSCLOUD has **Contributor** role

---

### ✅ Step 2: GitHub Variables (Replace Secrets)

**Navigate to:**
```
Repository → Settings → Secrets and variables → Actions → Variables
```

**Create these VARIABLES (not Secrets):**

| Variable Name | Value | Source |
|---------------|-------|--------|
| `AZURE_CLIENT_ID` | `12345678-1234-...` | PSCLOUD Application (client) ID |
| `AZURE_TENANT_ID` | `87654321-4321-...` | Your Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `abcdefgh-1234-...` | Your Azure Subscription ID |

**Important:**
- Use **Variables** tab, NOT **Secrets** tab
- These are not sensitive (OIDC trust validates via Azure)

---

### ✅ Step 3: Test the Workflow

1. **Commit the updated workflow:**
   ```bash
   git add .github/workflows/default_plan_unit_tests.yml
   git commit -m "Convert to OIDC authentication"
   git push
   ```

2. **Trigger the workflow:**
   - Push a commit to any branch, OR
   - Go to Actions → Default Plan Unit Tests → Re-run jobs

3. **Expected output:**
   ```
   ✅ Azure OIDC login successful
   {
     "environmentName": "AzureCloud",
     "id": "...",
     "name": "Your Subscription",
     ...
   }
   ```

4. **Tests should run** without any client secret errors

---

### ✅ Step 4: Cleanup Old Secrets (After Successful Test)

Once OIDC works, **delete these GitHub Secrets:**

```
Settings → Secrets and variables → Actions → Secrets
```

**Delete:**
- ❌ `TF_VAR_CLIENT_SECRET`
- ❌ `AZURE_CLIENT_SECRET`
- ⚠️ Keep `TF_VAR_CLIENT_ID` for now (migrate to variable later)
- ⚠️ Keep `TF_VAR_TENANT_ID` for now (migrate to variable later)
- ⚠️ Keep `TF_VAR_SUBSCRIPTION_ID` for now (migrate to variable later)

**After confirming OIDC works everywhere:**
1. Delete remaining secrets
2. Migrate to variables completely
3. Remove Azure Function secret rotation
4. Delete rotation workflows

---

## 🐛 Troubleshooting

### Issue: "Error: AADSTS70021: No matching federated identity record found"

**Solution:**
- Verify federated credential exists in Azure Portal
- Ensure Entity Type is **Environment** (not Branch/PR)
- Ensure Environment name matches: `terraformSecrets`
- Wait 5 minutes for Azure propagation

### Issue: "Error: Client assertion is not within its valid time range"

**Solution:**
- Clock skew issue
- Re-run the workflow (GitHub generates new token)

### Issue: Tests fail with "authentication failed"

**Solution:**
1. Check Docker has access to Azure credentials:
   ```yaml
   -v $HOME/.azure:/root/.azure:ro
   ```
2. Verify `ARM_USE_CLI=true` is set in Docker environment
3. Check Terraform provider supports OIDC (azurerm >= 3.0)

### Issue: "Permission denied" in tests

**Solution:**
- Verify PSCLOUD has **Contributor** role in Subscription IAM
- Check role assignment scope covers test resources

---

## 🎯 What This Achieves

### ✅ Security Improvements
- **No client secrets** stored in GitHub
- **Temporary tokens** expire after workflow
- **Zero rotation overhead** (no 60-day cycle)
- **Audit trail** via Azure AD sign-in logs

### ✅ Simplified Architecture
- ❌ No Azure Function needed
- ❌ No Microsoft Graph API permissions
- ❌ No Application Administrator role
- ❌ No rotation tracking issues
- ❌ No Teams notifications for rotation
- ❌ No 48-hour grace periods

### ✅ Operational Benefits
- **Automatic** - GitHub requests token on-demand
- **Scoped** - Only works from specific repo/environment
- **Modern** - Microsoft-recommended approach
- **Compliant** - Meets enterprise security standards

---

## 📊 Comparison

| Aspect | Old (Secrets) | New (OIDC) |
|--------|---------------|------------|
| Authentication | Long-lived secret | Temporary token |
| Rotation | Every 60 days | Automatic |
| Infrastructure | Azure Function + Storage | None |
| Permissions | Graph API + Admin role | RBAC only |
| Failure Risk | High (secret expiry) | Low (auto-refresh) |
| Setup Complexity | High | Medium |
| Operational Overhead | High | Minimal |
| Security Posture | Good | Excellent |

---

## 🚀 Next Steps

After OIDC works in `default_plan_unit_tests.yml`:

1. **Migrate other workflows:**
   - Convert any workflows using client secrets
   - Update deployment workflows
   - Update custom scripts

2. **Clean up Azure Function:**
   - Stop `azure-sp-secret-rotation` Function App
   - Delete rotation-related GitHub Actions
   - Remove cleanup tracking issues
   - Archive tmp-azure-sp-secret-rotation repo

3. **Update documentation:**
   - Update README with OIDC instructions
   - Document federated credential setup
   - Remove secret rotation documentation

4. **Verify compliance:**
   - Confirm security team approves OIDC
   - Update runbooks
   - Train team members

---

## 📞 Support

**If you encounter issues:**

1. Check Azure Activity Log for OIDC failures
2. Review GitHub Actions logs for authentication errors
3. Verify federated credential configuration
4. Check Azure RBAC role assignments
5. Test with `azure-oidc.yml` workflow first

**Common Success Indicator:**
```
Run Azure Login using OIDC
✅ Azure OIDC login successful
```

---

**🎉 You've successfully migrated from secret-based to OIDC authentication!**

*Migration completed: May 20, 2026*  
*Zero secrets, zero rotation, maximum security.*
