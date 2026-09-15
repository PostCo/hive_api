# Changelog

## [Unreleased]

### Added

- Rails-independent Hive API client foundation with fixed production and staging environments, defaulting safely to staging.
- Bounded Faraday connections with injectable adapters and safe JSON middleware.
- Shared resource and response-object foundations.
- Merchant-scoped bearer authentication and typed, credential-safe API errors.
- Hive rate-limit metadata and transport-error wrapping without automatic retries or logging.
- Return rules, paginated return listing, safe explicit page traversal, and individual return retrieval.
- Immutable, dedicated return response objects with deeply frozen provider evidence.
