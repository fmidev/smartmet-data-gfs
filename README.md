# SmartMet Data Ingestion Module for GFS Model

Download and convert NCEP GFS model for SmartMet Workstation and SmartMet Server.

## INSTALL
- yum install smartmet-data-gfs
- edit /smartmet/cnf/data/gfs.cnf

## BUILD RPM
- cd $HOME/rpmbuild/SOURCES/
- git clone https://github.com/fmidev/smartmet-data-gfs.git
- rpmbuild -ba smartmet-data-gfs/smartmet-data-gfs.spec
