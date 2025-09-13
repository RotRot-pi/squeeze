Name: squeeze 
Version: 1.0.1+2 
Release: 1%{?dist} 
Summary: A fast, private, cross-platform image compressor and resizer. 
License: Proprietary 
URL: https://github.com/ 
Vendor: Ramy 
Packager: Ramy 
BuildArch: x86_64

Source1: squeeze.desktop 
Source2: squeeze.png


%description
A fast, private, cross-platform image compressor and resizer. Built with Flutter.

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/pixmaps

cp -a "%{_topdir}/BUILD/%{name}/." "%{buildroot}%{_datadir}/%{name}/"
ln -s "../share/%{name}/%{name}" "%{buildroot}%{_bindir}/%{name}"
install -m 0644 "%{SOURCE1}" "%{buildroot}%{_datadir}/applications/%{name}.desktop"
install -m 0644 "%{SOURCE2}" "%{buildroot}%{_datadir}/pixmaps/%{name}.png"


%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/pixmaps/%{name}.png

%changelog
* Fri Sep 12 2025 Ramy you@example.com - 1.0.1+2-1
- Fixed an issue where the process doesn't work after the initial start until clearing the finished process and selecting the files again.
* Fri Sep 13 2024 Ramy you@example.com - 1.0.0+1-1
- Initial package
