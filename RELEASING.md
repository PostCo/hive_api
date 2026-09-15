## Releasing `hive_api`

This project uses Bundler's built-in gem release tasks.

### Prerequisites

- You have push access to the GitHub repository.
- You have a RubyGems.org account with MFA enabled and an API key configured locally by running `gem signin`.
- Your local `main` branch is up to date with `origin/main`.

### Prepare the release

1. **Decide the new version**
   - Choose the next version number (for example, `0.1.1` or `0.2.0`) following SemVer.

2. **Update the version constant**
   - Edit `lib/hive_api/version.rb` and update:
     - `HiveAPI::VERSION = "x.y.z"`

3. **Update docs**
   - Update `CHANGELOG.md` with a new section for the version and a short summary of changes.
   - Optionally update `README.md` if usage or the public API changed.
   - Keep the ownership boundary explicit: webhook handling, automatic polling, retries, caching,
     persistence, and business workflows remain caller responsibilities.

4. **Commit the changes**

   ```bash
   git status
   git add lib/hive_api/version.rb CHANGELOG.md README.md
   git commit -m "Bump version to vX.Y.Z"
   ```

   Replace `X.Y.Z` with the new version number.

5. **Ensure you are on `main` and pushed**

   ```bash
   git switch main
   git pull origin main
   git push origin main
   ```

6. **Verify the staging contract**
   - With a staging token supplied through `HIVE_API_TOKEN`, construct a client with
     `sandbox: true` and call `client.return_rules.get` and `client.returns.list(limit: 1)`.
   - When the list contains a return, call `client.returns.find(id: page.data.first.id)`.
   - When the list is empty, record that limitation in the Tapir staging milestone.
   - Never commit credentials, tokens, customer payloads, smoke output, or environment-specific
     secrets.

7. **Run the release**

   Use Bundler's release task, which runs tests and lint first:

   ```bash
   bundle exec rake release
   ```

   This will:

   - Run `rake spec` and `rake standard`.
   - Build the gem from `hive_api.gemspec`.
   - Create a git tag `vX.Y.Z` based on `HiveAPI::VERSION`.
   - Push the tag to `origin`.
   - Push the gem to RubyGems using your configured credentials and require MFA.

8. **Verify the release**

   - Check the tag on GitHub (for example, `vX.Y.Z`).
   - Check the gem page on RubyGems: `https://rubygems.org/gems/hive_api`.
   - Record the published version and tag in the Tapir integration milestone for dependency pinning.

### Notes

- If `bundle exec rake release` fails at any step, fix the issue and rerun the command.
- Do not manually create tags for versions that have not been released through this process; let
  `rake release` handle tagging.
- Do not add or update the Tapir dependency in this release; consuming and pinning `hive_api` is a
  separate integration milestone.
