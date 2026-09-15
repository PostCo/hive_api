## Releasing `hive_api`

This project follows the Exporto and Torque convention and uses Bundler's built-in gem release
tasks. Releases must be made from a reviewed commit on `main`.

### Prerequisites

- You have push access to the GitHub repository.
- You have a RubyGems.org account with MFA enabled and an API key configured locally by running
  `gem signin`.
- Your local `main` branch is clean and up to date with `origin/main`.
- You have a staging-only Hive token available through `HIVE_API_TOKEN`.

Never put a token on a command line that will be saved to shell history. Do not add credentials,
tokens, customer payloads, smoke output, or environment-specific secrets to this repository.

### Prepare the release

1. Choose the next version following SemVer and update `HiveAPI::VERSION` in
   `lib/hive_api/version.rb`.
2. Move the relevant entries from `Unreleased` into a dated section in `CHANGELOG.md` and update
   `README.md` when the public API changes.
3. Confirm the public boundary remains intentional: webhook handling, automatic polling, retries,
   caching, persistence, and business workflows are caller-owned.
4. Commit the release preparation and have it reviewed and merged.

### Verify the release candidate

From a clean, up-to-date `main` checkout, run the complete local suite:

```bash
bundle exec rake
bundle exec ruby -Ilib -e 'require "hive_api"; HiveAPI::Client; HiveAPI::Objects::ReturnResponse; abort "Rails loaded" if defined?(Rails); abort "Zeitwerk loaded" if defined?(Zeitwerk)'
gem build hive_api.gemspec
gem specification --local hive_api-0.1.0.gem files
```

Inspect the final command's output. The gem should contain only `lib/`, `README.md`, `CHANGELOG.md`,
and `LICENSE.txt`; it must not contain `.env` files, credentials, tokens, customer payloads, specs,
or the contract smoke script.

Then run the read-only staging contract check without echoing or retaining the token:

```bash
read -s HIVE_API_TOKEN
export HIVE_API_TOKEN
bundle exec rake contract:smoke
unset HIVE_API_TOKEN
```

The check validates `GET /return_rules` and `GET /returns`. If staging contains a return, it also
validates `GET /returns/{id}` using the first returned ID. If staging has no returns, record the
reported no-data limitation in the Tapir staging milestone before continuing.

### Publish

Run Bundler's release task:

```bash
bundle exec rake release
```

The task first runs `spec` and `standard`, then builds the gem, creates and pushes the version tag,
and publishes to RubyGems using the locally configured credentials. Complete the RubyGems MFA
prompt when requested. Do not create the version tag manually.

### Verify and record

- Confirm the immutable `vX.Y.Z` tag points to the reviewed `main` commit on GitHub.
- Confirm the version is available at `https://rubygems.org/gems/hive_api`.
- Record the published version and tag in the Tapir integration milestone for dependency pinning.
- Leave the Tapir dependency unchanged here; consuming and pinning the gem is a separate milestone.

If the release task fails, resolve the failure before rerunning it. Before retrying, check whether
the tag or gem version was already published so an immutable release is not recreated inconsistently.
