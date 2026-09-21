
# Community-Contributed Features

Community contributed features are submitted by community members to help expand the set of features that the project maintainers are capable of adding to the project on their own. 

> [!CAUTION]
> Community members are responsible for maintaining these features. While project maintainers try to verify these features work as expected when merged, they cannot guarantee future releases will not break them. If you encounter issues while using these features, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-azure/discussions) or open a Pull Request to fix them. As a last resort, create a GitHub Issue for the concern.

## Community-Contributed Feature Expectations

- As with other features, community contributed features should include unit tests which add to the level of community confidence for the feature. Unit tests should also help indicate if a problem occurs with the feature in a future release.

- Community contributed features should be disabled by default. If applicable, a boolean configuration variable named COMMUNITY_ENABLE_<COMMUNITY_FEATURE> should be implemented for the community feature. The boolean configuration variable should serve as a way to enable or disable the community feature. 

- Multiple community contributed feature configuration variables may exist for the same feature, although if the feature is disabled, they should have no effect on the overall behavior of the project. 

- Additional community contributed feature configuration variables should use the COMMUNITY_ prefix to indicate they are part of a community contributed feature.

## Submitting a Community-Contributed Feature

Submit a community contributed Feature by creating a GitHub PR in this project. The PR should include the source code, unit tests and any required documentation including expected content for the [docs/community/community-config-vars.md](community-config-vars.md) file.

## What if a Community-Contributed Feature breaks

If you encounter issues while using a community contributed feature, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-azure/discussions) or open a Pull Request to fix the issue. As a last resort, you can create a GitHub Issue to inform the community about the problem.

If a community contributed feature is implemented as required, disabling the community feature should serve as a way to remove any impact that it has on the project. Community contributed features that affect the project when disabled should be re-worked to prevent that behavior.