---
name: 'Issue: Bug report'
about: Let us know about an unexpected error or incorrect behavior
title: "[BUG]"
labels: bug
assignees: ''

---

<!--
Welcome,

Thanks for opening an issue. The more information you provide, the easier it is for us to assess the problem, prioritize, assign, develop, then release a fix.

The IAC/Deployment team

-->

### Terraform Version

<!---
We ask this to be sure you are currently running a supported terraform version from your work environment. 

Run `terraform version` to show the version, and paste the result between the ``` marks below.

If you are not running the latest version of Terraform we support, please try upgrading because your issue may have already been fixed.

If you're not sure which versions are supported, here's a link : https://github.com/sassoftware/viya4-iac-azure#terraform to help.
-->

```bash
...
```

### Terraform Configuration Files

<!--
Paste the relevant parts of your Terraform configuration between the ``` marks below.

Configuration files you write in Terraform language tell Terraform what plugins to install, what infrastructure to create, and what data to fetch.
These are the `*.tf` files in this directory.

The relevant parts should come from your `terraform.tfvars` file or equivalent and small snippets of the `*.tf` file/files that seem to be causing the error.

For Terraform config files larger than a few resources, provide a link to the file/files in a current repository, rather than copy-pasting multiple files in here.

For security reasons, do not copy and paste any sensitive material in this issue.
-->

```terraform
...
```

### Expected Behavior

<!--
What should have happened?
-->

### Actual Behavior

<!--
What actually happened? Here you can include output and information from your terraform run.
If there's a need for more information you can turn on logging by setting `TF_LOG=DEBUG` and include that output.

Here is an example of running terraform with the TF_LOG env set:

TF_LOG=DEBUG terraform apply ...

-->

```bash
...
```

### Steps to Reproduce

<!--
Please list the full steps required to reproduce the issue, for example:
1. `terraform init`
2. `terraform apply`
-->

### Additional Context

<!--
Are there anything atypical about your situation that we should know? For example: Are you passing any unusual command line options or environment variables to opt-in to non-default behavior?
-->

### References

<!--
Are there any other GitHub issues (open or closed) or Pull Requests that should be linked here? For example:

- #123

-->
