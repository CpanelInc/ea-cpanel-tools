# EA4 packages that do not have the `ea-` prefix in their name.

Profiles, out of the box, only operate on packages that begin with `ea-`.

In order to include packages with other prefixes we need the prefixes defined.

In order to define one create a file in `/etc/cpanel/ea4/additional-pkg-prefixes/` named after the prefix.

For example, if CloudLinux did a subset of their `alt-` packages as a group of web stack specific ones prefixed w/ `altea-`, they would need to ensure `/etc/cpanel/ea4/additional-pkg-prefixes/altea` existed.

The file should be empty unless you are [Doing a subset of a additional-pkg-prefixes prefix](#doing-a-subset-of-a-additional-pkg-prefixes-prefix) per below.

## ⚠️  Do not create additional-pkg-prefixes that will match packages that are not EA4 related!!

**Doing so could break your system due to how profile resolution operates**.

How so?

Here is how it works essentially: Given a list of EA4 packages means “I want these packages (and their deps) and not the others”. So if I choose `ea-foo` and not `ea-bar` and I have `ea-bar` installed then the transaction will install/upgrade `ea-foo` and uninstall `ea-bar`. A more real world example would be checking the box for `ea-php85` and unchecking `ea-php80`. I want PHP 8.5, I no longer want PHP 8.0.

Understanding that, imagine you created `alt-` as an additional prefix (understanding that `alt-` has EA4 packages as well as many other non-web-stack things). Now choose a few `alt-` packages: the resolution described above will mean you want other `alt-`s to be removed … including things unrelated to the web stack like **the kernel**.

That is why we use we used `altea-` as the example above.

## Doing a subset of a additional-pkg-prefixes prefix

If naming is too difficult you can create a prefix that will match packages that are not EA4 related and limit it to a subset of only the EA4 related packages for that OS.

You do so by putting the list in the prefix file. One package per line, no surrounding white space, no empty lines, no comments. The list must match the reality of what is availble on that OS.

Do not install this file unless the cpanel is new enough to support the subset-of-additional-pkg-prefixes feature. You can determine that by ensuring this outputs `0.03` or greater: `/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PackMan -E 'say $Cpanel::PackMan::VERSION'`

## Special Dep Caveat

For `dnf` systems if you get something like this:

```
!!!! There was a problem with the additional-pkg-prefix “alt”, it will be left out !!
	Error: The package “alt-libcurlssl11” conflicts and we need to install it resolve deps
```

And if that conflict is errouneous it should be added to `/etc/cpanel/ea4/additional-pkg-prefixes-ignore_prefix_dep/alt`

Like the other prefix file it should be: One package per line, no surrounding white space, no empty lines, no comments.

# About Recommendations

[Documentation](https://documentation.cpanel.net/display/EA4/EasyApache+4+Recommendations)

## When a PHP version goes EOL

1. Add the eol recommendation to it.

## When a PHP version is added

1. Add the standard PHP recommendations to it.
2. Update the PHP INI meta info if needed.

## When a PHP version is updated

1. Update the PHP INI meta info if needed.
