Name:           ea-cpanel-tools
Version:        1.0
Release:        2%{?dist}
Summary:        EasyApache4 Tools that interacts with cPanel
License:        GPL
Group:          System Environment/Configuration
URL:            http://www.cpanel.net
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot

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
rm -rf $RPM_BUILD_ROOT
install -m 755 -d $RPM_BUILD_ROOT/usr/local/bin
echo -n "Current working dir = "
pwd

install -m 755 ../SOURCES/ea_current_to_profile $RPM_BUILD_ROOT/usr/local/bin
install -m 755 ../SOURCES/ea_install_profile $RPM_BUILD_ROOT/usr/local/bin

%files
%defattr(-,root,root)
/usr/local/bin/ea_current_to_profile
/usr/local/bin/ea_install_profile

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Mon Aug 31 2015 Julian Brown<julian.brown@cpanel.net> - 1.0-2
- Changed name of the rpm to ea-cpanel-tools

* Fri Aug 28 2015 Julian Brown<julian.brown@cpanel.net> - 1.0-1
- Initial Commit
