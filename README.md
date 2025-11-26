# EA4 packages that do not have the `ea-` prefix in their name.

Profiles, out of the box, only operate on packages that begin with `ea-`.

In order to include packages with other prefixes we need the prefixes defined.

In order to define one create a file in `/etc/cpanel/ea4/additional-pkg-prefixes/` named after the prefix.

For example, if CloudLinux did a subset of their `alt-` packages as a group of web stack specific ones prefixed w/ `altea-`, they would need to ensure `/etc/cpanel/ea4/additional-pkg-prefixes/altea` existed.

It is suggested to include helpful information about the prefix in the prefix’s file.

## ⚠️  Do not create additional-pkg-prefixes that will match packages that are not EA4 related!!

**Doing so could break your system due to how profile resolution operates**.

How so?

Here is how it works essentially: Given a list of EA4 packages means “I want these packages (and their deps) and not the others”. So if I choose `ea-foo` and not `ea-bar` and I have `ea-bar` installed then the transaction will install/upgrade `ea-foo` and uninstall `ea-bar`. A more real world example would be checking the box for `ea-php85` and unchecking `ea-php80`. I want PHP 8.5, I no longer want PHP 8.0.

Understanding that, imagine you created `alt-` as an additional prefix (understanding that `alt-` has EA4 packages as well as many other non-web-stack things). Now choose a few `alt-` packages: the resolution described above will mean you want other `alt-`s to be removed … including things unrelated to the web stack like **the kernel**.

That is why we use we used `altea-` as the example above.

# About Recommendations

[Documentation](https://documentation.cpanel.net/display/EA4/EasyApache+4+Recommendations)

## When a PHP version goes EOL

1. Add the eol recommendation to it.

## When a PHP version is added

1. Add the standard PHP recommendations to it.
2. Update the PHP INI meta info if needed.

## When a PHP version is updated

1. Update the PHP INI meta info if needed.
