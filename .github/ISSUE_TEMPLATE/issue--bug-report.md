---
name: 'Bug report'
about: Let us know about an unexpected error or incorrect behavior
labels: bug, new

---

<!--
Welcome,

Thanks for opening an issue. The more information you provide, the easier it is for us to assess the problem, prioritize, assign, develop, then release a fix.

The SAS Viya 4 IaC team

-->

### Terraform Version

<!---
We ask this to be sure you are currently running a supported terraform version from your work environment. 

Run `./files/tools/iac_tooling_version.sh` to show the version, and paste the result between the ``` marks below.

If you are not running the latest version of Terraform we support, please try upgrading because your issue may have already been fixed.

If you're not sure which versions are supported, here's a link : https://github.com/sassoftware/viya4-iac-azure#terraform to help.
-->

```bash
...
```

### Terraform Variable File

<!--
Paste the relevant parts of your Terraform variables between the ``` marks below.

The relevant parts should come from your `terraform.tfvars` file or equivalent and small snippets of the `*.tf` file/files that seem to be causing the error.

For security reasons, do not copy and paste any sensitive information in this issue, like account information and passwords etc.
-->

```terraform
...
```

### Steps to Reproduce

<!--
Please list the full steps required to reproduce the issue, for example:
1. `terraform init`
2. `terraform apply`
-->

### Expected Behavior

<!--
What should have happened?
-->

### Actual Behavior

<!--
What actually happened? Here you can include output and information from your terraform run.
-->

```bash
...
```

### Additional Context

<!--
Are there anything atypical about your situation that we should know? For example: Are you passing any unusual command line options or environment variables to opt-in to non-default behavior?
-->

### References

<!--
Are there any other GitHub issues (open or closed) or Pull Requests that should be linked here? For example:

- #123

-->
