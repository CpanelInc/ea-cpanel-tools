# elevate\_pkg\_renames

A utility for managing the package-rename mappings used by `ea_current_to_profile` during ELevate OS upgrades.

## Background

When ELevating between OS versions (e.g. AlmaLinux 8 → AlmaLinux 9), some EA4 packages are renamed. For example, `ea-ruby27-mod_passenger` on A8 becomes `ea-apache24-mod-passenger` on A9. Without a mapping, these packages are dropped from the generated profile, breaking applications after the upgrade.

When a package is renamed, its old dependencies (e.g. `ea-ruby27-ruby`, `ea-ruby27-rubygems`) are still installed but won't exist on the target OS. Without an ignore list, these dependencies generate noisy "not available" warnings. The `ignore_deps` field lets you silence those warnings — the old dependencies are naturally removed when the profile is built with the new package.

The mappings live in `SOURCES/target-os-pkg-renames.json`, a JSON file keyed by target OS. This utility manages that file so you don't have to edit it by hand.

## Usage

```
./elevate_pkg_renames COMMAND [OPTIONS]
```

### Commands

#### `list` — Show current mappings

```bash
# List all mappings
./elevate_pkg_renames list

# Filter by target OS
./elevate_pkg_renames list --os=CentOS_9
```

**Example output:**
```
CentOS_9:
  ea-ruby27-mod_passenger -> ea-apache24-mod-passenger
    ignore: /^ea-ruby27-ruby/
    ignore: ea-ruby27-mod_passenger-doc
```

#### `add` — Add a new mapping

```bash
./elevate_pkg_renames add --os=CentOS_9 --from=ea-old-pkg --to=ea-new-pkg

# Optionally include ignore_deps patterns (comma-separated)
./elevate_pkg_renames add --os=CentOS_9 --from=ea-old-pkg --to=ea-new-pkg \
  --ignore-deps=ea-old-lib,/^ea-old-ruby/
```

Fails if the mapping already exists (use `edit` to change it).

#### `edit` — Change an existing mapping

```bash
./elevate_pkg_renames edit --os=CentOS_9 --from=ea-old-pkg --to=ea-newer-pkg

# Replace the ignore_deps list entirely
./elevate_pkg_renames edit --os=CentOS_9 --from=ea-old-pkg --to=ea-newer-pkg \
  --ignore-deps=ea-replaced-dep
```

Without `--ignore-deps`, existing ignore\_deps are preserved. With `--ignore-deps`, the list is replaced.

Fails if the mapping does not exist (use `add` to create it).

#### `remove` — Remove a mapping

```bash
./elevate_pkg_renames remove --os=CentOS_9 --from=ea-old-pkg
```

Empty OS sections are automatically cleaned up.

#### `add-ignore` — Add an ignore\_deps pattern to an existing rename

```bash
./elevate_pkg_renames add-ignore --os=CentOS_9 \
  --from=ea-ruby27-mod_passenger --dep=ea-ruby27-ruby

# Regex patterns are enclosed in forward slashes
./elevate_pkg_renames add-ignore --os=CentOS_9 \
  --from=ea-ruby27-mod_passenger --dep=/^ea-ruby27-ruby/
```

#### `remove-ignore` — Remove an ignore\_deps pattern

```bash
./elevate_pkg_renames remove-ignore --os=CentOS_9 \
  --from=ea-ruby27-mod_passenger --dep=ea-ruby27-ruby
```

When the last ignore\_deps pattern is removed, the entry collapses back to a simple string.

## JSON File Format

The file `SOURCES/target-os-pkg-renames.json` is keyed by target OS name (matching the OBS project aliases used by `ea_current_to_profile --target-os`).

Simple renames (no ignore\_deps) use a plain string value. Renames with ignore\_deps use an object:

```json
{
   "CentOS_9" : {
      "ea-simple-rename" : "ea-new-name",
      "ea-ruby27-mod_passenger" : {
         "ignore_deps" : [
            "/^ea-ruby27-ruby/",
            "ea-ruby27-mod_passenger-doc"
         ],
         "to" : "ea-apache24-mod-passenger"
      }
   }
}
```

### ignore\_deps patterns

Each pattern can be:
- **Literal**: `ea-ruby27-ruby` — exact match (underscores are normalized to dashes)
- **Regex**: `/^ea-ruby27-ruby/` — matched as a Perl regex against each package name

## How It Works With ea\_current\_to\_profile

When `ea_current_to_profile --target-os=CentOS_9` runs:

1. It loads the rename map and ignore\_deps for the target OS
2. It pre-computes which renames will fire (new name exists and is not experimental)
3. For each installed package:
   - If a rename exists and the new name is available, it substitutes the new name
   - If the package matches an active rename's ignore\_deps, it is silently skipped
   - Otherwise, packages not on the target OS are dropped with a warning
4. The profile's `os_upgrade` section tracks:
   - `renamed_pkgs` — what was renamed
   - `ignored_deps` — what was silently skipped
   - `dropped_pkgs` — what was dropped
