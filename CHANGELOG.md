# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.4.1] - 2020-02-05
### Fixed
- Fix status page not expecting URL params in DATABASE_URL #154

## [3.4.0] - 2020-01-30
### Added
- Add a concern for the #tag and #untag methods to share common code #153
- Add a StatusController for use in healthchecks that can be mapped to /health #143

### Removed
- Removed unwanted RBAC files #152

## [3.3.1] - 2020-01-15
### Fixed
- Log errors as well as returning them in the response #147

## [3.3.0] - 2020-01-09
### Changed
- Switched from semver to simver (only x.y) versioning for the OpenAPI doc #144
- Removed RBAC log message #142

## [3.2.0] - 2019-12-18
### Added
- Add support for instance/tag and instance/untag with an Array request body #136, #139, #140

## [3.1.0] - 2019-11-13
### Changed
- Loosen ties between controllers and models. Allow schema overrides #131

## [3.0.0] - 2019-11-08
### Breaking Changes
- Rename gem from manageiq-api-common to insights-api-common-rails and rename all classes. #132

### Changed
- Fix params_for_update to support Hash/Array #133

## [2.1.0] - 2019-11-07
### Added
- Add support for sorting result collections #122

### Changed
- Change RBAC sharing/unsharing to be account based #130

## [2.0.1] - 2019-10-23
### Fixed
- Fix permitted params for nested objects #129
- Fix regex and add tests for filtering #128
- Pull in missed seeding PR #126
- Fix error responses for filtering #125

## [2.0.0] - 2019-10-17
### Breaking Changes
- Add ExceptionHandling mixin and consolidate ApiError rescue_from #114

### Changed
- Update to openapi_parser v0.6.1 (will break tests due to changed error messages) #124

### Added
- Import shared RBAC code #106
- Add 404 responses to the openapi generator #117

## [1.1.0] - 2019-10-15
### Added
- Add support for case insensitive filtering #123

## [1.0.2] - 2019-10-07
### Fixed
- Fix reference to GraphQLRequest #120

## [1.0.1] - 2019-10-07
### Fixed
- Fix next and prev page links on collections #118 & #119

## [1.0.0] - 2019-10-04
### Breaking Changes
- Namespace dynamically defined GraphQL API version modules under ManageIQ::API::Common::GraphQL::Api #105

### Added
- New entitlements for Ansible and Migrations #113 and use them #115
- Forwarding of persona headers #109

### Changed
- Extract GraphQLRequest to a schema object rather than inline #110
- Update to openapi_parser v0.5.0 #108

### Fixed
- Fixed errors around already defined constants in GraphQL #112
- Allow GraphQL generator to support paths with IDs like /primary/{primary_id}/ #107
- Constant problems related to GraphQL namespace #105

## [0.1.0] - 2019-09-24
### Initial release to rubygems.org

[Unreleased]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.4.1...HEAD
[3.4.1]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.3.1...v3.4.0
[3.3.1]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v2.1.0...v3.0.0
[2.1.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/RedHatInsights/insights-api-common-rails/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/RedHatInsights/insights-api-common-rails/releases/tag/v0.1.0
