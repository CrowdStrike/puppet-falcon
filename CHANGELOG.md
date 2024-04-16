<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v0.10.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.10.0) - 2024-04-16

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.9.0...v0.10.0)

### Other

- Update Gemfile [#90](https://github.com/CrowdStrike/puppet-falcon/pull/90) ([ffalor](https://github.com/ffalor))
- allow proxy settings to be set for sensor download [#89](https://github.com/CrowdStrike/puppet-falcon/pull/89) ([ffalor](https://github.com/ffalor))

## [v0.9.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.9.0) - 2023-11-02

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.8.0...v0.9.0)

### Added

- puppet8 support [#84](https://github.com/CrowdStrike/puppet-falcon/pull/84) ([ffalor](https://github.com/ffalor))

## [v0.8.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.8.0) - 2023-08-30

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.7.1...v0.8.0)

### Added

- Accept Sensitive for CID [#79](https://github.com/CrowdStrike/puppet-falcon/pull/79) ([cocker-cc](https://github.com/cocker-cc))

## [v0.7.1](https://github.com/CrowdStrike/puppet-falcon/tree/v0.7.1) - 2023-05-15

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.7.0...v0.7.1)

### Fixed

- fix: user-agent version logic [#75](https://github.com/CrowdStrike/puppet-falcon/pull/75) ([ffalor](https://github.com/ffalor))

## [v0.7.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.7.0) - 2023-03-30

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.6.1...v0.7.0)

### Added

- Add facts [#62](https://github.com/CrowdStrike/puppet-falcon/pull/62) ([ffalor](https://github.com/ffalor))

### Fixed

- Fix issue with s390x support on sensor API [#66](https://github.com/CrowdStrike/puppet-falcon/pull/66) ([carlosmmatos](https://github.com/carlosmmatos))

## [v0.6.1](https://github.com/CrowdStrike/puppet-falcon/tree/v0.6.1) - 2022-10-31

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.6.0...v0.6.1)

### Fixed

- fix `version` api install method [#56](https://github.com/CrowdStrike/puppet-falcon/pull/56) ([ffalor](https://github.com/ffalor))

## [v0.6.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.6.0) - 2022-10-24

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.5.1...v0.6.0)

### Added

- Add `tags` support for linux [#54](https://github.com/CrowdStrike/puppet-falcon/pull/54) ([ffalor](https://github.com/ffalor))

## [v0.5.1](https://github.com/CrowdStrike/puppet-falcon/tree/v0.5.1) - 2022-10-12

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.5.0...v0.5.1)

### Fixed

- fix version lookup issue [#48](https://github.com/CrowdStrike/puppet-falcon/pull/48) ([ffalor](https://github.com/ffalor))

## [v0.5.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.5.0) - 2022-10-07

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.4.0...v0.5.0)

### Added

- add `aid` to fact `falcon` [#45](https://github.com/CrowdStrike/puppet-falcon/pull/45) ([ffalor](https://github.com/ffalor))

## [v0.4.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.4.0) - 2022-09-22

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.3.1...v0.4.0)

### Added

- add proxy support [#41](https://github.com/CrowdStrike/puppet-falcon/pull/41) ([ffalor](https://github.com/ffalor))

## [v0.3.1](https://github.com/CrowdStrike/puppet-falcon/tree/v0.3.1) - 2022-09-01

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.3.0...v0.3.1)

### Fixed

- Version tracking issues [#38](https://github.com/CrowdStrike/puppet-falcon/pull/38) ([mtkraai](https://github.com/mtkraai))

## [v0.3.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.3.0) - 2022-08-23

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.2.1...v0.3.0)

### Added

- Add mac install support [#35](https://github.com/CrowdStrike/puppet-falcon/pull/35) ([ffalor](https://github.com/ffalor))
- add arm64 support [#33](https://github.com/CrowdStrike/puppet-falcon/pull/33) ([ffalor](https://github.com/ffalor))

### Fixed

- Fix incorrect arm64 assumptions [#36](https://github.com/CrowdStrike/puppet-falcon/pull/36) ([ffalor](https://github.com/ffalor))

## [v0.2.1](https://github.com/CrowdStrike/puppet-falcon/tree/v0.2.1) - 2022-07-09

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.2.0...v0.2.1)

### Fixed

- fix package `os_version` query [#30](https://github.com/CrowdStrike/puppet-falcon/pull/30) ([ffalor](https://github.com/ffalor))

## [v0.2.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.2.0) - 2022-07-07

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/v0.1.0...v0.2.0)

### Added

- Add windows support for falcon [#27](https://github.com/CrowdStrike/puppet-falcon/pull/27) ([ffalor](https://github.com/ffalor))

## [v0.1.0](https://github.com/CrowdStrike/puppet-falcon/tree/v0.1.0) - 2022-04-19

[Full Changelog](https://github.com/CrowdStrike/puppet-falcon/compare/de2b319e3814b7090dc645138151eb842920e153...v0.1.0)
