Name:           ea-cpanel-tools
Version:        1.0
# Doing release_prefix this way for Release allows for OBS-proof versioning, See EA-4548 for more details
%define release_prefix 42
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
Source7:        ea4-metainfo.json
Source8:        phpini_directives.yaml
Source9:        phpini_directive_links.yaml
Source10:       recommendations__ea-phpNN__important-pkgs.json
Source11:       recommendations__ea-rubyNN__eol.json

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

mkdir -p %{buildroot}/etc/cpanel/ea4
%{__install} %{SOURCE7} %{buildroot}/etc/cpanel/ea4/ea4-metainfo.json

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php
mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php-cli
mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php-common
%{__install} %{SOURCE4} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php/dso.json
%{__install} %{SOURCE10} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php-cli/important.json
%{__install} %{SOURCE10} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54-php-common/important.json
for pkg in php php-cli php-common; do
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php55-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php56-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php70-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php71-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php72-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php73-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php74-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php80-${pkg}
done

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54
%{__install} %{SOURCE6} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54/eol.json
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php55
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php56
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php70
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php71
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php72

%if 0%{?rhel} > 6
    mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger
    %{__install} %{SOURCE11} %{buildroot}/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger/eol.json
%endif

mkdir -p %{buildroot}/etc/yum/vars
%if 0%{?rhel} > 6
    %if 0%{?rhel} == 8
        echo "CentOS_8" > %{buildroot}/etc/yum/vars/ea4_repo_uri_os
    %endif
    %if 0%{?rhel} == 7
        echo "CentOS_7" > %{buildroot}/etc/yum/vars/ea4_repo_uri_os
    %endif
%endif

%if 0%{?rhel} == 6
    echo "CentOS_6.5_standard" > %{buildroot}/etc/yum/vars/ea4_repo_uri_os
%endif

%{__mkdir_p} %{buildroot}/usr/local/cpanel/whostmgr/etc/
%{__install} %{SOURCE8} %{buildroot}/usr/local/cpanel/whostmgr/etc/
%{__install} %{SOURCE9} %{buildroot}/usr/local/cpanel/whostmgr/etc/

%files
%defattr(0755,root,root,0755)
/usr/local/bin/*

%defattr(0644,root,root,0755)
/etc/cpanel/ea4/recommendations
/etc/cpanel/ea4/ea4-metainfo.json
/usr/local/cpanel/whostmgr/etc/phpini_directive_links.yaml
/usr/local/cpanel/whostmgr/etc/phpini_directives.yaml

%attr(0644,root,root) /etc/yum/vars/ea4_repo_uri_os

%clean
rm -rf %{buildroot}

%changelog
* Wed Mar 03 2021 Travis Holloway <t.holloway@cpanel.net> - 1.0-42
- EA-9612: Update default PHP to 7.4

* Thu Jan 07 2021 Daniel Muey <dan@cpanel.net> - 1.0-41
- ZC-6815: Add ea-nginx-standalone to additional_packages

* Fri Dec 18 2020 Daniel Muey <dan@cpanel.net> - 1.0-40
- ZC-7904: Add eol recommendation for ruby24 on C7 and beyond (6 only has ruby24)

* Mon Dec 07 2020 Cory McIntire <cory@cpanel.net> - 1.0-39
- EA-9444: Add PHP 7.2 to EOL recommendations

* Wed Oct 28 2020 Daniel Muey <dan@cpanel.net> - 1.0-38
- ZC-7308: Updates for PHP 8

* Tue Oct 27 2020 Daniel Muey <dan@cpanel.net> - 1.0-37
- ZC-7307: Specify default directory index and PHP FPM’s `security_limit_extensions` that so they can be updated without requiring a ULC updated/backport

* Thu Sep 24 2020 Daniel Muey <dan@cpanel.net> - 1.0-36
- ZC-7629: Add mod sec 3.0 apache connector to additonal packages list

* Mon Aug 31 2020 Daniel Muey <dan@cpanel.net> - 1.0-35
- ZC-7001: Make PHP 7.3 the default PHP

* Mon Aug 31 2020 Daniel Muey <dan@cpanel.net> - 1.0-34
- ZC-7471: Add ea-modsec30-connector-nginx to ea4-metainfo.json’s additional_packages

* Thu Aug 27 2020 Daniel Muey <dan@cpanel.net> - 1.0-33
- ZC-7463: Add ea-modsec30-rules-owasp-crs to ea4-metainfo.json’s additional_packages

* Mon Aug 10 2020 Daniel Muey <dan@cpanel.net> - 1.0-32
- ZC-7320: Add `ea-modsec2-rules-owasp-crs` to the additional packages list

* Wed May 20 2020 Julian Brown <julian.brown@cpanel.net> - 1.0-31
- ZC-6837: Build on CentOS 8

* Thu Apr 16 2020 Daniel Muey <dan@cpanel.net> - 1.0-30
- ZC-4935: Add recommendation for -php-cli and -php-common removal

* Wed Apr 15 2020 Tim Mullin <tim@cpanel.net> - 1.0-29
- EA-8960: Update end-of-life PHP phrase

* Wed Apr 08 2020 Tim Mullin <tim@cpanel.net> - 1.0-28
- EA-8930: Update max_execution_time default to 30

* Tue Feb 04 2020 Daniel Muey <dan@cpanel.net> - 1.0-27
- ZC-5894: Move PHP.ini directive data to RPM

* Thu Jan 02 2020 Cory McIntire <cory@cpanel.net> - 1.0-26
- EA-8784: Add PHP 7.1 to EOL recommendations

* Tue Oct 22 2019 Julian Brown <julian.brown@cpanel.net> - 1.0-25
- ZC-5740: Add yum var ea4_repo_uri_os

* Thu Apr 11 2019 Daniel Muey <dan@cpanel.net> - 1.0-24
- ZC-4963: Add `ea-nginx` to Affition Packages list

* Fri Apr 5 2019 J. Nick Koston <nick@cpanel.net> - 1.0-23
- CPANEL-26711: ea_current_to_profile should use a prefix like ea_install_profile

* Wed Feb 6 2019 J. Nick Koston <nick@cpanel.net> - 1.0-22
- EA-8200: Add --firstinstall flag to ea_install_profile

* Thu Jan 17 2019 Daniel Muey <dan@cpanel.net> - 1.0-21
- ZC-4650: Add ea4-metainfo.json file

* Mon Dec 24 2018 Daniel Muey <dan@cpanel.net> - 1.0-20
- ZC-4595: add PHP 5.6 and 7.0 EOL recommendations, add `filter` to recommendations hash

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
