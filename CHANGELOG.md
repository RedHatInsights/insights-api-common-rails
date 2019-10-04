# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2017-06-20
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

[Unreleased]: https://github.com/ManageIQ/manageiq-api-common/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ManageIQ/manageiq-api-common/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/ManageIQ/manageiq-api-common/releases/tag/v0.1.0
