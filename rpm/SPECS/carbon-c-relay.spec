%define name     carbon-c-relay
%define version  1.11

Name:            %{name}           
Version:         %{version}
Release:         1%{?dist}
Summary:         Enhanced C implementation of Carbon relay, aggregator and rewriter
Group:           Applications/Communications
License:         Apache 2.0
URL:             https://github.com/grobian/carbon-c-relay
Source0:         %{name}-%{version}.tar.gz
ExcludeArch:     s390 s390x
BuildRequires  : systemd
%{?systemd_requires} 

%description
Enhanced C implementation of Carbon relay, aggregator and rewriter
The relay is a simple program that reads its routing information from a file. 
The command line arguments allow to set the location for this file, as well 
as the amount of dispatchers (worker threads) to use for reading the data 
from incoming connections and passing them onto the right destination(s). 
The route file supports two main constructs: clusters and matches. The first 
define groups of hosts data metrics can be sent to, the latter define which 
metrics should be sent to which cluster. 

%prep
rm -rf $RPM_BUILD_DIR/*
cp -a %{_topdir}/../src $RPM_BUILD_DIR/
cp -a %{_topdir}/../config $RPM_BUILD_DIR/
cp -a %{_topdir}/../Makefile $RPM_BUILD_DIR/
make dist DISTDIR=%{_sourcedir} 

%build
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
install -d %{buildroot}%{_sysconfdir}/carbon
install -d %{buildroot}/usr/sbin
make install PREFIX=%{buildroot}/usr DESTDIR=%{buildroot}%{_sysconfdir}/carbon
install -m 644 %{_topdir}/%{name}.conf %{buildroot}%{_sysconfdir}/carbon/%{name}.conf
install -D -m 644 %{_topdir}/%{name}.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/%{name}
install -D -m 755 %{_topdir}/%{name}.service %{buildroot}%{_unitdir}/%{name}.service

%clean
rm -rf %{buildroot}

%post
if [ $1 -eq 1 ]; then
        %systemd_post %{name}.service
        useradd -d /tmp -M -s /bin/false --system -G daemon carbon
fi

%preun
%systemd_preun %{name}.service

%files
%{_sbindir}/%{name}
%attr(755, root, root) %{_unitdir}/%{name}.service
%attr(644, root, root) %config(noreplace) %{_sysconfdir}/carbon/%{name}.conf
%attr(644, root, root) %config(noreplace) %{_sysconfdir}/sysconfig/%{name}

%changelog
* Mon Jun 19 2017 Vuong Lam Pham <vuong.pham@gooddata.com>
- %{name} %{version}
