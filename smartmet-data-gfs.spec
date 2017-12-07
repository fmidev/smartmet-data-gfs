%define smartmetroot /smartmet

Name:           smartmet-data-gfs
Version:        17.12.7
Release:        1%{?dist}.fmi
Summary:        SmartMet Data GFS
Group:          System Environment/Base
License:        MIT
URL:            https://github.com/fmidev/smartmet-data-gfs
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch

%{?el6:Requires: smartmet-qdconversion}
%{?el7:Requires: smartmet-qdtools}
Requires:	curl
Requires:	lbzip2


%description
SmartMet Data Ingestion Module for GFS Model

%prep

%build

%pre

%install
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT
cd $RPM_BUILD_ROOT

mkdir -p .%{smartmetroot}/cnf/cron/{cron.d,cron.hourly}
mkdir -p .%{smartmetroot}/cnf/data
mkdir -p .%{smartmetroot}/tmp/data/gfs
mkdir -p .%{smartmetroot}/logs/data
mkdir -p .%{smartmetroot}/run/data/gfs/{bin,cnf}

cat > %{buildroot}%{smartmetroot}/cnf/cron/cron.d/gfs.cron <<EOF
# Model available after
# 00 UTC = 03:20 UTC
15 * * * * utcrun  3 /smartmet/run/data/gfs/bin/get_gfs.sh 
# 06 UTC = 09:20 UTC
15 * * * * utcrun  9 /smartmet/run/data/gfs/bin/get_gfs.sh 
# 12 UTC = 15:20 UTC
15 * * * * utcrun 15 /smartmet/run/data/gfs/bin/get_gfs.sh 
# 18 UTC = 21:20 UTC
15 * * * * utcrun 21 /smartmet/run/data/gfs/bin/get_gfs.sh 
EOF

cat > %{buildroot}%{smartmetroot}/cnf/cron/cron.hourly/clean_data_gfs <<EOF
#!/bin/sh
# Clean GFS data
cleaner -maxfiles 4 '_gfs_.*_surface.sqd' %{smartmetroot}/data/gfs
cleaner -maxfiles 4 '_gfs_.*_pressure.sqd' %{smartmetroot}/data/gfs
cleaner -maxfiles 4 '_gfs_.*_surface.sqd' %{smartmetroot}/editor/in
cleaner -maxfiles 4 '_gfs_.*_pressure.sqd' %{smartmetroot}/editor/in
EOF

cat > %{buildroot}%{smartmetroot}/run/data/gfs/cnf/gfs-surface.st <<EOF
// Precipitation
var rr3h = PAR354 // make variable from 3 hour precip

IF(FHOUR % 6 == 0)
{
     // 6 hour zone
     PAR354 = PAR354 * 2  - avgt(-3, -3, rr3h)
}
EOF

cat > %{buildroot}%{smartmetroot}/cnf/data/gfs.cnf <<EOF
AREA="caribbean"

TOP=40
BOTTOM=-10
LEFT=-120
RIGHT=0

# Default: ("0 3 126" "132 6 192")
INTERVALS=("0 3 126" "132 6 192")

# Values 0p25 0p50
RESOLUTION=0p25

#GRIB_COPY_DEST= 
EOF


install -m 755 %_topdir/SOURCES/smartmet-data-gfs/get_gfs.sh %{buildroot}%{smartmetroot}/run/data/gfs/bin/

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,smartmet,smartmet,-)
%config(noreplace) %{smartmetroot}/cnf/data/gfs.cnf
%config(noreplace) %{smartmetroot}/cnf/cron/cron.d/gfs.cron
%config(noreplace) %attr(0755,smartmet,smartmet) %{smartmetroot}/cnf/cron/cron.hourly/clean_data_gfs
%{smartmetroot}/*

%changelog
* Thu Dec 7 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.12.7-1%{?dist}.fmi
- rsync now creates sub director for each model run

* Wed Nov 8 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.11.8-1%{?dist}.fmi
- Updated spec file

* Tue Nov 7 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.11.7-2%{?dist}.fmi
- Added additional test for grib download
- Changed grib rsync to happen after every file download

* Tue Nov 7 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.11.7-1%{?dist}.fmi
- Fixed grib testing to be more robust

* Mon Nov 6 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.11.6-2%{?dist}.fmi
- Improved logging and functionality if not /smartmet sytem

* Mon Nov 6 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.11.6-1%{?dist}.fmi
- Switched from bzip2 to lbzip2 for faster compression

* Sun May 7 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.5.7-1%{?dist}.fmi
- Fixed log printing when run from cron

* Thu May 5 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.5.5-1.el7.fmi
- Removed ISCRON variable from cron file, is it now located at mkcron

* Thu May 4 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.5.4-1.el7.fmi
- Updated cron file to have ISCRON variable

* Wed Apr 19 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.4.19-2.el7.fmi
- Updated gfs.cnf to have correct intervals 

* Wed Apr 19 2017 Mikko Rauhala <mikko.rauhala@fmi.fi> 17.4.19-1.el7.fmi
- Updated dependencies

* Wed Jun 3 2015 Santeri Oksman <santeri.oksman@fmi.fi> 15.6.3-1.el7.fmi
- RHEL 7 version

* Sat Jan 24 2015 Mikko Rauhala <mikko.rauhala@fmi.fi> 15.1.24-1.el6.fmi
- Added level 10 to be processed by gribtoqd

* Fri Jan 23 2015 Mikko Rauhala <mikko.rauhala@fmi.fi> 15.1.23-1.el6.fmi
- Fixed level name for TCDC

* Fri Jan 16 2015 Mikko Rauhala <mikko.rauhala@fmi.fi> 15.1.16-1.el6.fmi
- Support for different resolutions, support for GRIB copy destination

* Thu Jan 15 2015 Mikko Rauhala <mikko.rauhala@fmi.fi> 15.1.15-1.el6.fmi
- Changed filenaming according changes made by NOAA

* Fri Aug 8 2013 Mikko Rauhala <mikko.rauhala@fmi.fi> 13.8.8-1.el6.fmi
- Initial build 1.0.0
