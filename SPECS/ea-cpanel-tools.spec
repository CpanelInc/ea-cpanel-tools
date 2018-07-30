Name:           ea-cpanel-tools
Version:        1.0
# Doing release_prefix this way for Release allows for OBS-proof versioning, See EA-4548 for more details
%define release_prefix 19
Release:        %{release_prefix}%{?dist}.cpanel
Summary:        EasyApache4 Tools that interacts with cPanel
License:        GPL
Group:          Applications/File
URL:            http://www.cpanel.net
Vendor: cPanel, Inc.
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Source1:        ea_current_to_profile
Source2:        ea_install_profile
Source3:        ea_convert_php_ini
Source4:        recommendations__ea-phpNN-php__dso.json
Source5:        ea_sync_user_phpini_settings
Source6:        recommendations__ea-phpNN__eol.json

# if I do not have autoreq=0, rpm build will recognize that the ea_
# scripts need perl and some Cpanel pm's to be on the disk.
# unfortunately they cannot be satisfied via the requires: tags.
Autoreq:        0

# I require the file specifically because cPanel is using perl 5.14
# at the time of this writing which is provided by rpm cpanel-perl-514
# but may in the future be doing say 5.20 or 5.22.  This gets past that
# limitation.

Requires: /usr/local/cpanel/3rdparty/bin/perl

%description
This package provides tools for working with cPanel.

%install
rm -rf %{buildroot}
%{__mkdir_p} %{buildroot}/usr/local/bin
%{__install} %{SOURCE1} %{buildroot}/usr/local/bin
%{__install} %{SOURCE2} %{buildroot}/usr/local/bin
%{__install} %{SOURCE3} %{buildroot}/usr/local/bin
%{__install} %{SOURCE5} %{buildroot}/usr/local/bin

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php
%{__install} %{SOURCE4} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php/dso.json
ln -s ea-php54-php %{buildroot}/etc/cpanel/ea4/recommendations/ea-php55-php
ln -s ea-php54-php %{buildroot}/etc/cpanel/ea4/recommendations/ea-php56-php
ln -s ea-php54-php %{buildroot}/etc/cpanel/ea4/recommendations/ea-php70-php
ln -s ea-php54-php %{buildroot}/etc/cpanel/ea4/recommendations/ea-php71-php

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54
%{__install} %{SOURCE6} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54/eol.json
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php55

%files
%defattr(0755,root,root,0755)
/usr/local/bin/*

%defattr(0644,root,root,0755)
/etc/cpanel/ea4/recommendations

%clean
rm -rf %{buildroot}

%changelog
* Mon Jul 30 2018 Tim Mullin <tim@cpanel.net> - 1.0-19
- EA-7549: If the php config file is a symlink, and the force option is used, remove the symlink so the file can be written.

* Wed Apr 18 2018 Daniel Muey <dan@cpanel.net> - 1.0-18
- EA-7173: Add recommendation for EOL PHPs

* Mon Jun 05 2017 Dan Muey <dan@cpanel.net> - 1.0-17
- EA-6344: ea_convert_php_ini fixups: add missing require, allow it to parse suphp conf handlers, add usage comment to package

* Mon May 15 2017 Dan Muey <dan@cpanel.net> - 1.0-16
- ZC-2606: no longer treat local.ini as special

* Fri Apr 28 2017 Cory McIntire <cory@cpanel.net> - 1.0-15
- ZC-2563: Add a --all-users flag

* Tue Apr 25 2017 Dan Muey <dan@cpanel.net> - 1.0-14
- ZC-2549: Add ea_sync_user_phpini_settings script

* Mon Mar 27 2017 Charan Angara <charan@cpanel.net> - 1.0-13
- EA-6101: Rephrased description in PHP DSO recommendation.

* Tue Mar 07 2017 Dan Muey <dan@cpanel.net> - 1.0-12
- EA-6025: Add top level 'level' and adjust options' 'level' of PHP DSO recommendation

* Mon Mar 06 2017 Dan Muey <dan@cpanel.net> - 1.0-11
- EA-6021: revamp EA4 Recommendations data for new spec

* Fri Feb 24 2017 Dan Muey <dan@cpanel.net> - 1.0-10
- EA-5964: add initial EA4 Recommendations data

* Fri Dec 16 2016 Jacob Perkins <jacob.perkins@cpanel.net> - 1.0-9
- Added vendor field (EA-5493)

* Wed Oct 05 2016 Dan Muey <dan@cpanel.net> - 1.0-8
- EA-5320: filter out profile packages that do not exist on the server

* Wed Sep 28 2016 Dan Muey <dan@cpanel.net> - 1.0-7
- EA-5065: Have ea_install_profile to use new resolution method if it can

* Fri Jul 08 2016 S. Kurt Newman <kurt.newman@cpanel.net> - 1.0-6
- Added ea_convert_php_ini script (EA-4772)
- Updated rpm spec file to conform to standard macros
- Fixed several rpmlint errors

* Mon Jun 20 2016 Dan Muey <dan@cpanel.net> - 1.0-5
- EA-4383: Update Release value to OBS-proof versioning

* Wed May 11 2016 Dan Muey <dan@cpanel.net> - 1.0-4
- Give some indication that package resolution is happening and may take a bit

* Tue Sep 01 2015 Julian Brown<julian.brown@cpanel.net> - 1.0-3
- Use the 'ea' namespace in the resolve_multi_op call.

* Mon Aug 31 2015 Julian Brown<julian.brown@cpanel.net> - 1.0-2
- Changed name of the rpm to ea-cpanel-tools

* Fri Aug 28 2015 Julian Brown<julian.brown@cpanel.net> - 1.0-1
- Initial Commit
