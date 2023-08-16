# EA4 packages that do not have the `ea-` prefix in their name.

Profiles, out of the box, only operate on packages that begin with `ea-`.

In order to include packages with other prefixes we need the prefixes defined.

In order to define one create a file in `/etc/cpanel/ea4/additional-pkg-prefixes/` named after the prefix.

For example, if CloudLinux did a subset of their `alt-` packages as a group of web stack specific ones prefixed w/ `altea-`, they would need to ensure `/etc/cpanel/ea4/additional-pkg-prefixes/altea` existed.

It is suggested to include helpful information about the prefix in the prefix’s file.

# About Recommendations

[Documentation](https://documentation.cpanel.net/display/EA4/EasyApache+4+Recommendations)

## When a PHP version goes EOL

1. Add the eol recommendation to it.

## When a PHP version is added

1. Add the standard PHP recommendations to it.
2. Update the PHP INI meta info if needed.

## When a PHP version is updated

1. Update the PHP INI meta info if needed.
