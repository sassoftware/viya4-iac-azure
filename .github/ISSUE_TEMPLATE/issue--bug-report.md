---
name: 'Issue: Bug report'
about: Let us know about unexpected error or incorrect behavior
title: "[BUG]"
labels: bug
assignees: ''

---

<!--
Welcome,

Thanks for opening an issue. The more information you provide, the easier it is for us to asses the problem, prioritize, assign, develop, then release a fix.

The IAC/Deployment team

-->

### Terraform Version
<!---
We ask this to be sure you are currently running a supported terraform version from your work environment. 

Run `terraform version` to show the version, and paste the result between the ``` marks below.

If you are not running the latest version of Terraform, please try upgrading because your issue may have already been fixed.
-->

```
...
```

### Terraform Configuration Files
<!--
Paste the relevant parts of your Terraform configuration between the ``` marks below.

The relevant parts should come from your `terraform.tfvars` file or equivalent  and a small snippet of the section that seems to be causing the error.

For Terraform configs larger than a few resources, or that involve multiple files, please make a GitHub repository that we can clone or provide a link to file in a current repository, rather than copy-pasting multiple files in here. For security, do not copy and paste any sensitive material in this issue.
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
What actually happened? Here you can include output and information from your terraform run. If there's a need for more information you can turn on debugging by setting `TF_LOG=DEBUG` and include that output.
-->

```
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
