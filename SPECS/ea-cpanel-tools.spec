Name:           ea-cpanel-tools
Version:        1.0
# Doing release_prefix this way for Release allows for OBS-proof versioning, See EA-4548 for more details
%define release_prefix 108
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
Source12:       001-ensure-nobody
Source13:       option-flags-README.md
Source14:       recommendations__ea-nginx-http2__on.json
Source15:       recommendations__ea-nginx-http2__off.json
Source16:       pkg-manifest.json
Source17:       recommendations__ea-tomcat85__eol.json
Source18:       recommendations__ea-apache24-mod_cpanel__eol.json

# if I do not have autoreq=0, rpm build will recognize that the ea_
# scripts need perl and some Cpanel pm's to be on the disk.
# unfortunately they cannot be satisfied via the requires: tags.
Autoreq:        0

# I require the file specifically because cPanel is using perl 5.14
# at the time of this writing which is provided by rpm cpanel-perl-514
# but may in the future be doing say 5.20 or 5.22.  This gets past that
# limitation.

Requires: /usr/local/cpanel/3rdparty/bin/perl

%if 0%{?rhel} > 7
    %define hooks_base $RPM_BUILD_ROOT%{_sysconfdir}/dnf/universal-hooks/multi_pkgs/transaction
    %define hooks_base_sys %{_sysconfdir}/dnf/universal-hooks/multi_pkgs/transaction
    %define hooks_base_pre $RPM_BUILD_ROOT%{_sysconfdir}/dnf/universal-hooks/multi_pkgs/pre_transaction
    %define hooks_base_pre_sys %{_sysconfdir}/dnf/universal-hooks/multi_pkgs/pre_transaction
%else
    %define hooks_base $RPM_BUILD_ROOT%{_sysconfdir}/yum/universal-hooks/multi_pkgs/posttrans
    %define hooks_base_sys %{_sysconfdir}/yum/universal-hooks/multi_pkgs/posttrans
    %define hooks_base_pre $RPM_BUILD_ROOT%{_sysconfdir}/yum/universal-hooks/multi_pkgs/pretrans
    %define hooks_base_pre_sys %{_sysconfdir}/yum/universal-hooks/multi_pkgs/pretrans
%endif

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

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-nginx-http2
%{__install} %{SOURCE14} %{buildroot}/etc/cpanel/ea4/recommendations/ea-nginx-http2/on.json
%{__install} %{SOURCE15} %{buildroot}/etc/cpanel/ea4/recommendations/ea-nginx-http2/off.json
for pkg in ea-nginx-gzip ea-nginx-brotli ea-nginx-standalone ea-nginx-njs ea-nginx-passenger; do
    mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/${pkg}
    ln -s ../ea-nginx-http2/off.json %{buildroot}/etc/cpanel/ea4/recommendations/${pkg}/off.json
done

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
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php81-${pkg}
    ln -s ea-php54-${pkg} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php82-${pkg}
done

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54
%{__install} %{SOURCE6} %{buildroot}/etc/cpanel/ea4/recommendations/ea-php54/eol.json
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php55
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php56
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php70
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php71
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php72
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php73
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php74
ln -s ea-php54 %{buildroot}/etc/cpanel/ea4/recommendations/ea-php80

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-tomcat85
%{__install} %{SOURCE17} %{buildroot}/etc/cpanel/ea4/recommendations/ea-tomcat85/eol.json

mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-apache24-mod_cpanel
%{__install} %{SOURCE18} %{buildroot}/etc/cpanel/ea4/recommendations/ea-apache24-mod_cpanel/eol.json

%if 0%{?rhel} > 6
    mkdir -p %{buildroot}/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger
    %{__install} %{SOURCE11} %{buildroot}/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger/eol.json
%endif

mkdir -p %{hooks_base}/ea-__WILDCARD__
mkdir -p %{hooks_base_pre}/ea-__WILDCARD__
install %{SOURCE12} %{hooks_base}/ea-__WILDCARD__/001-ensure-nobody
install %{SOURCE12} %{hooks_base_pre}/ea-__WILDCARD__/001-ensure-nobody

mkdir -p %{buildroot}/etc/cpanel/ea4/option-flags/
install %{SOURCE13} %{buildroot}/etc/cpanel/ea4/option-flags/README.md

mkdir -p %{buildroot}/etc/cpanel/ea4/profiles/
install %{SOURCE16} %{buildroot}/etc/cpanel/ea4/profiles/pkg-manifest.json

mkdir -p %{buildroot}/etc/yum/vars
%if 0%{?rhel} > 6
    %if 0%{?rhel} == 10
        echo "Almalinux_10" > %{buildroot}/etc/yum/vars/ea4_repo_uri_os
    %endif
    %if 0%{?rhel} == 9
        echo "CentOS_9" > %{buildroot}/etc/yum/vars/ea4_repo_uri_os
    %endif
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

mkdir -p %{buildroot}/var/log/cpanel-server-traffic/web
chmod 700 %{buildroot}/var/log/cpanel-server-traffic
chmod 700 %{buildroot}/var/log/cpanel-server-traffic/web

%files
%defattr(0755,root,root,0755)
/usr/local/bin/*

%defattr(0644,root,root,0755)
/etc/cpanel/ea4/recommendations
/etc/cpanel/ea4/ea4-metainfo.json
/usr/local/cpanel/whostmgr/etc/phpini_directive_links.yaml
/usr/local/cpanel/whostmgr/etc/phpini_directives.yaml

%attr(0644,root,root) /etc/cpanel/ea4/option-flags/README.md

%attr(0644,root,root) /etc/yum/vars/ea4_repo_uri_os

%attr(0755,root,root) %{hooks_base_sys}/ea-__WILDCARD__/001-ensure-nobody
%attr(0755,root,root) %{hooks_base_pre_sys}/ea-__WILDCARD__/001-ensure-nobody
%attr(0644,root,root) /etc/cpanel/ea4/profiles/pkg-manifest.json

%defattr(-,root,root,0700)
/var/log/cpanel-server-traffic
/var/log/cpanel-server-traffic/web

%clean
rm -rf %{buildroot}

%changelog
* Tue May 06 2025 Julian Brown <julian.brown@webpros.com> - 1.0-108
- ZC-12810: Preparing for Almalinux 10

* Wed Apr 16 2025 Dan Muey <daniel.muey@webpros.com> - 1.0-107
- ZC-12775: temporarily remove `wpsquared.site` from `tech_domains`

* Wed Apr 16 2025 Chris Castillo <chris.castillo@webpros.com> - 1.0-106
- ZC-12773: Fix directory permissions for Ubuntu

* Fri Apr 04 2025 Chris Castillo <chris.castillo@webpros.com> - 1.0-105
- ZC-12736: Create webserver traffic logging directory.

* Wed Mar 05 2025 Chris Castillo <chris.castillo@webpros.com> - 1.0-104
- ZC-12668: Add tech domains list

* Mon Mar 03 2025 Brian Mendoza <brian.mendoza@webpros.com> - 1.0-103
- ZC-12618: Update manifest for sourceguardian84

* Wed Feb 19 2025 Dan Muey <daniel.muey@webpros.com> - 1.0-102
- ZC-12574: Update manifest for ioncube 14’s PHP 8.4

* Thu Jan 09 2025 Dan Muey <daniel.muey@webpros.com> - 1.0-101
- EA-12626: Update Manifest

* Mon Dec 02 2024 Dan Muey <daniel.muey@webpros.com> - 1.0-100
- ZC-12237: Add PHP 8.4

* Fri Nov 15 2024 Dan Muey <daniel.muey@webpros.com> - 1.0-99
- ZC-12346: Update obs_project_aliases to match reality

* Thu Oct 24 2024 Julian Brown <julian.brown@cpanel.net> - 1.0-98
- ZC-12253: Add ea-ioncube14

* Thu Oct 03 2024 Julian Brown <julian.brown@cpanel.net> - 1.0-97
- ZC-12191: Add ea-apache24-mod-wasm

* Mon Sep 16 2024 Julian Brown <julian.brown@cpanel.net> - 1.0-96
- ZC-12141: Add ioncube and sourceguardian to php83

* Fri Aug 09 2024 Julian Brown <julian.brown@cpanel.net> - 1.0-95
- ZC-4769: Update manifest for ea-apache24-mod-maxminddb

* Tue May 14 2024 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-94
- ZC-11823: Add new container package ea-valkey72 to the metainfo and update manifest

* Fri May 10 2024 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-93
- ZC-11822: Add ea-nodejs22 to additional packages list and manifest

* Tue May 07 2024 Dan Muey <dan@cpanel.net> - 1.0-92
- ZC-11811: Add ea-apache24-mod_cpanel eol.json to recommendations

* Fri May 03 2024 Sloane Bernstein <sloane@cpanel.net> - 1.0-91
- ZC-11759: Mark ea-tomcat85 as EOL in EA4 recommendations

* Mon Apr 29 2024 Dan Muey <dan@cpanel.net> - 1.0-90
- ZC-11752: Update Manifest for mod lsapi update

* Wed Mar 20 2024 Dan Muey <dan@cpanel.net> - 1.0-89
- ZC-11698: Update manifest for new ea-noop-u20 pkg and recent repo cleanups

* Mon Mar 11 2024 Sloane Bernstein <sloane@cpanel.net> - 1.0-88
- ZC-11660: Allow compatibility for profiles which include third-party packages

* Mon Mar 11 2024 Julian Brown <julian.brown@webpros.com> - 1.0-87
- ZC-11662: Update manifest because of changes to EA4-experimental

* Thu Feb 15 2024 Dan Muey <dan@cpanel.net> - 1.0-86
- ZC-11627: Update manifest under canonical write so its ordered correctly

* Tue Jan 30 2024 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-85
- ZC-11501: Allow compatibility between profiles from RHEL to DEB and vice versa

* Mon Jan 29 2024 Travis Holloway <t.holloway@cpanel.net> - 1.0-84
- EA-11937: Remove ea-tomcat85 for CentOS_8 in pkg-manifest.json

* Mon Jan 08 2024 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-83
- ZC-11503: Add PHP 8.0 EOL recommendation

* Wed Dec 20 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-82
- ZC-11475: ea-php83 built for C7

* Tue Dec 05 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-81
- ZC-11175: Adding PHP8.3

* Fri Nov 10 2023 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-80
- ZC-11384: Update deprecated directives for PHP 8.3

* Thu Sep 21 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-79
- ZC-11156: Add ea-ioncube13

* Mon Aug 14 2023 Dan Muey <dan@cpanel.net> - 1.0-78
- ZC-11033: Add support for packages w/out an `ea-` prefix in EA4 profiles
- ZC-11135: Add ea-nodejs18 and ea-nodejs20 to additional packages list
- ZC-11149: Add touchfile for nginx cpwrap that will ignore memory limits and set it to unlimited to readme

* Thu Aug 10 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-77
- ZC-11122: Add ea-tomcat101 to the manifest.

* Mon Aug 07 2023 Brian Mendoza <brian.mendozacpanel.net> - 1.0-76
- ZC-10396: Add ea-nginx-echo to `additional_packages`

* Thu Aug 03 2023 Dan Muey <dan@cpanel.net> - 1.0-75
- ZC-11053: Add ea-tomcat101 to container-based package list

* Mon Jun 19 2023 Dan Muey <dan@cpanel.net> - 1.0-74
- ZC-10971: Add support for profile’s `pre` list

* Thu May 25 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-73
- ZC-10931: Updated for ea-libc-client

* Thu May 18 2023 Dan Muey <dan@cpanel.net> - 1.0-72
- ZC-10955: Update manifest for post reset of OBS flags (Makefile disables only; no manual disables)

* Thu May 04 2023 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-71
- ZC-10474: Add ea-nginx-headers-more to `additional_packages`
- ZC-10320: Add Ubuntu 22 to manifest

* Wed Apr 26 2023 Julian Brown <julian.brown@cpanel.net> - 1.0-70
- ZC-10561: Add ea-php82-php-memcached

* Thu Apr 13 2023 Dan Muey <dan@cpanel.net> - 1.0-69
- ZC-10899: Add ea-nginx-echo to `additional_packages`

* Thu Mar 09 2023 Tim Mullin <tim@cpanel.net> - 1.0-68
- EA-10893: Fix ea_install_profile to return non-zero exit code upon failure

* Tue Feb 28 2023 Sloane Bernstein <sloane@cpanel.net> - 1.0-67
- EA-11271: Let `ea_current_to_profile` ignore OpenSSL devel packages under `--target-os`

* Tue Jan 10 2023 Dan Muey <dan@cpanel.net> - 1.0-66
- ZC-10586: Update manifest for new C7 PHP 8.2 pkgs

* Thu Dec 22 2022 Dan Muey <dan@cpanel.net> - 1.0-65
- ZC-10447: update manifest for A9 and PHP 8.2, make PHP 8.1 the default for EA4
- ZC-10581: update ea4 recommendations to match the PHP reality

* Tue Dec 13 2022 Dan Muey <dan@cpanel.net> - 1.0-64
- ZC-10548: have `ea_current_to_profile` ignore `-debuginfo` packages under `--target-os`

* Tue Nov 22 2022 Dan Muey <dan@cpanel.net> - 1.0-63
- ZC-10494: Update PHP INI directive data for PHP 8.2 changes

* Mon Oct 31 2022 Brian Mendoza <brian.mendoza@cpanel.net> - 1.0-62
- ZC-10359: Update manifest

* Fri Oct 14 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-61
- ZC-10350: Update manifest

* Thu Sep 29 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-60
- ZC-10009: Add changes so that it builds on AlmaLinux 9

* Tue May 10 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-59
- ZC-9918: Correct names of packages on Ubuntu

* Mon May 02 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-58
- ZC-9960: Add new container package ea-redis62 to the manifest

* Wed Mar 30 2022 Dan Muey <dan@cpanel.net> - 1.0-57
- ZC-9886: Add meta info to target-os profile && update EA4-production manifest when updating EA4 manifest
- EA-10600: Add PHP 7.3 to EOL recommendations

* Thu Mar 17 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-56
- ZC-9849: Add pkg_manifest.json and add target to ea_current_to_profile
- ZC-9854: Add ea-nginx-njs to additional packages and recommendations.

* Wed Mar 16 2022 Julian Brown <julian.brown@cpanel.net> - 1.0-55
- ZC-9823: Set php default version to 8.0

* Thu Feb 17 2022 Dan Muey <dan@cpanel.net> - 1.0-54
- ZC-9758: Add ea-nginx-brotli to additional packages list && do http2-like toggle off recommendations
- ZC-9759: add `container_based_packages` list to ea4-metainfo.json

* Tue Feb 01 2022 Dan Muey <dan@cpanel.net> - 1.0-53
- ZC-9690: Add ea-nginx-gzip to Additional Packages list

* Mon Jan 10 2022 Dan Muey <dan@cpanel.net> - 1.0-52
- ZC-9636: Add recommends for ea-nginx-http2

* Wed Jan 05 2022 Dan Muey <dan@cpanel.net> - 1.0-51
- ZC-9632: Add ea-nginx-http2 to EA4 `Additional Packages`

* Tue Dec 07 2021 Dan Muey <dan@cpanel.net> - 1.0-50
- ZC-9570: Replace EOL `ea-nodejs10` w/ LTS `ea-nodejs16` in ea4-metainfo.json’s additional pkgs

* Wed Nov 24 2021 Dan Muey <dan@cpanel.net> - 1.0-49
- ZC-9528: Add /etc/cpanel/ea4/option-flags/README.md

* Thu Sep 23 2021 Dan Muey <dan@cpanel.net> - 1.0-48
- ZC-9307: Rolling “ea-cpanel-tools” back to “0a3c415”: ea-apache24-mod-passenger shows up under Apache modules so additional packages was not necessary

* Thu Sep 23 2021 Dan Muey <dan@cpanel.net> - 1.0-47
- ZC-9303: Add ea-apache24-mod-passenger to additional packages list for EA4 UI

* Tue Sep 07 2021 Dan Muey <dan@cpanel.net> - 1.0-46
- ZC-9253: install nobody hook via ea-cpanel-tools so its available for pre-txn profile install

* Mon Aug 16 2021 Travis Holloway <t.holloway@cpanel.net> - 1.0-45
- EA-10037: Update open_basedir to have correct Changeable value in phpini_directives.yaml

* Thu Jul 01 2021 Daniel Muey <dan@cpanel.net> - 1.0-44
- ZC-9029: have post install output be clear that it was complete

* Fri Mar 12 2021 Julian Brown <julian.brown@cpanel.net> - 1.0-43
- ZC-8595: ZC-8595-ea-cpanel-tools: Add missing directives

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

