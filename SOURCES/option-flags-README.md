# EA4 Option Flags

## /etc/cpanel/ea4/option-flags/

This directory will contain flag files to inform EA4 how you want things to be.

1. To activate a flag it just needs to exist: `touch /etc/cpanel/ea4/option-flags/FLAG-NAME`
   * Better yet, inform your future selves by putting information in the file:
   `echo "We need this to frobnigate widgets better, see issue 42 for details" > /etc/cpanel/ea4/option-flags/FLAG-NAME`
2. To deactivate flag it just needs to not exist: `rm /etc/cpanel/ea4/option-flags/FLAG-NAME`

About the names:

1. The flag name is the file name relative to `/etc/cpanel/ea4/option-flags/`.
   * e.g. `FLAG-NAME` would be `/etc/cpanel/ea4/option-flags/FLAG-NAME`
2. Related flags should be grouped by using directory structure.
   * e.g. The flag names `foo/bar`, `foo/baz`, `foo/wop/zig`, and `foo/wop/zag` would be these paths:
      * /etc/cpanel/ea4/option-flags/foo/bar
      * /etc/cpanel/ea4/option-flags/foo/baz
      * /etc/cpanel/ea4/option-flags/foo/wop/zig
      * /etc/cpanel/ea4/option-flags/foo/wop/zag
3. All available flags will be documented in this document under “Available Flags”

## Available Flags

### `set-USER_ID`

This will cause Apache vhosts to set the `USER_ID` env var and NGINX server blocks to set
the `$USER_ID` variable with the numeric uid of the user that owns the domain in question.
