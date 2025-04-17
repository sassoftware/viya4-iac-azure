# How to Contribute
This project is community-driven, and we'd love to accept your patches and contributions.
We just ask that you follow our contribution guidelines when you do. Refer
to the [Contributor Handbook](https://sassoftware.github.io/contributor-handbook.html)
for guidance.

## Contributor License Agreement
Contributions to this project must be accompanied by a signed [Contributor Agreement](ContributorAgreement.txt).
You (or your employer) retain the copyright to your contribution; this agreement simply grants
us permission to use and redistribute your contributions as part of the project.

## Code Reviews
All submissions to this project—including submissions from project members—require
review. Our review process typically involves performing unit tests, development
tests, integration tests, and security scans.

## Pull Request Requirement

### Automated Tests
All contributors are expected to include appropriate tests to ensure code quality
and maintainability. This may include unit and/or integration tests as applicable
to the scope of the changes.  We have a developed a Golang testing framework using
[Terratest](https://terratest.gruntwork.io/) for unit tests and are in the process
of developing integration tests. Please refer to our [Testing Philosopy](./docs/user/TestingPhilosophy.md)
documentation for more information on our testing framework. If you need additional
help and guidance, we are happy to help you navigate it by providing continuous
collaboration within the pull request.

### Conventional Commits
All pull requests must follow the [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/)**
standard for commit messages. This helps maintain a consistent and meaningful
commit history. Pull requests with commits that do not follow the Conventional
Commit format will not be merged.

### Developer Certificate of Origin Sign-Off
This project requires all commits to be signed off in accordance with the [Developer Certificate of Origin (DCO)](https://developercertificate.org/).
By signing off your commits, you certify that you have the right to submit the
contribution under the open source license used by this project.

To sign off your commits, use the --signoff flag with git commit:

```bash
git commit --signoff -m "Your commit message"
```

This will add a Signed-off-by line to your commit message, e.g.:

```bash
Signed-off-by: You Name <your.email@example.com>
```

For more information, please refer to https://probot.github.io/apps/dco/

### Linter Analysis Checks
All pull requests must pass our automated analysis checks before they can be
merged. These checks include:

- **Hadolint** – for Dockerfile best practices
- **ShellCheck** – for shell script issues
- **TFLint** – for Terraform code quality
- **Gitleaks** – for detecting hardcoded secrets and sensitive information

## Security Scans
To ensure that all submissions meet our security and quality standards, we perform
security scans using internal SAS infrastructure. Contributions might be subjected
to security scans before they can be accepted. Reporting of any Common Vulnerabilities
and Exposures (CVEs) that are detected is not available in this project at this
time.