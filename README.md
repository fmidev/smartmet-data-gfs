# SmartMet Data Ingestion Module for GFS Model

Download and convert NCEP GFS model for SmartMet Workstation and SmartMet Server.

## INSTALL
- rpm -Uvh https://download.fmi.fi/smartmet-open/rhel/7/x86_64/smartmet-open-release-17.9.28-1.el7.fmi.noarch.rpm
- yum install smartmet-data-gfs
- edit /smartmet/cnf/data/gfs.cnf

## BUILD RPM
- cd $HOME/rpmbuild/SOURCES/
- git clone https://github.com/fmidev/smartmet-data-gfs.git
- rpmbuild -ba smartmet-data-gfs/smartmet-data-gfs.spec