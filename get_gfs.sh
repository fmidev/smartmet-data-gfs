#!/bin/sh
#
# Finnish Meteorological Institute / Mikko Rauhala (2015-2016)
#
# SmartMet Data Ingestion Module for GFS Model
#

# Load Configuration 
if [ -s /smartmet/cnf/data/gfs.cnf ]; then
    . /smartmet/cnf/data/gfs.cnf
fi

if [ -s gfs.cnf ]; then
    . gfs.cnf
fi

# Setup defaults for the configuration

if [ -z "$AREA" ]; then
    AREA=world
fi

if [ -z "$TOP" ]; then
    TOP=90
fi

if [ -z "$BOTTOM" ]; then
    BOTTOM=-90
fi

if [ -z "$LEFT" ]; then
    LEFT=0
fi

if [ -z "$RIGHT" ]; then
    RIGHT=360
fi

if [ -z "$INTERVALS" ]; then
    INTERVALS=("0 3 126" "132 6 192")
fi

if [ -z "$RESOLUTION" ]; then
    RESOLUTION=0p25
fi

while getopts  "a:b:dg:i:l:r:t:" flag
do
  case "$flag" in
        a) AREA=$OPTARG;;
        d) DRYRUN=1;;
        g) RESOLUTION=$OPTARG;;
        i) INTERVALS=("$OPTARG");;
        l) LEFT=$OPTARG;;
        r) RIGHT=$OPTARG;;
        t) TOP=$OPTARG;;
        b) BOTTOM=$OPTARG;;
  esac
done

STEP=6
# Model Reference Time
RT=`date -u +%s -d '-3 hours'`
RT="$(( $RT / ($STEP * 3600) * ($STEP * 3600) ))"
RT_HOUR=`date -u -d@$RT +%H`
RT_DATE_HH=`date -u -d@$RT +%Y%m%d%H`
RT_DATE_HHMM=`date -u -d@$RT +%Y%m%d%H%M`
RT_ISO=`date -u -d@$RT +%Y-%m-%dT%H:%M:%SZ`

if [ -d /smartmet ]; then
    OUT=/smartmet/data/gfs/$AREA
    CNF=/smartmet/run/data/gfs/cnf
    EDITOR=/smartmet/editor/in
    TMP=/smartmet/tmp/data/gfs_${AREA}_${RESOLUTION}_${RT_DATE_HHMM}
    LOGFILE=/smartmet/logs/data/gfs${RT_HOUR}.log
else
    OUT=$HOME/data/gfs/$AREA
    CNF=/smartmet/run/data/gfs/cnf
    EDITOR=/smartmet/editor/in
    TMP=/tmp/gfs_${AREA}_${RESOLUTION}_${RT_DATE_HHMM}
    LOGFILE=/smartmet/logs/data/gfs${RT_HOUR}.log
fi

OUTNAME=${RT_DATE_HHMM}_gfs_$AREA

# Log everything
if [ ! -z "$ISCRON" ]; then
    exec &> $LOGFILE
fi

echo "Model Reference Time: $RT_ISO"
echo "Resolution: $RESOLUTION"
echo "Area: $AREA left:$LEFT right:$RIGHT top:$TOP bottom:$BOTTOM"
echo -n "Interval(s): "
for l in "${INTERVALS[@]}"
do
    echo -n "$l "
done
echo ""
echo "Temporary directory: $TMP"
echo "Output directory: $OUT"
echo "Output surface level file: ${OUTNAME}_surface.sqd"
echo "Output pressure level file: ${OUTNAME}_pressure.sqd"


if [ -z "$DRYRUN" ]; then
    mkdir -p $TMP/grb
    mkdir -p $OUT/{surface,pressure}/querydata
fi

function runBacground()
{
    downloadStep $1 &
    ((dnum=dnum+1))
    if [ $(($dnum % 6)) == 0 ]; then
	wait
    fi
}

function testFile()
{
    if [ -s $1 ]; then
    # check return value, break if successful (0)
	gdalinfo $1 &>/dev/null
	if [ $? = 0 ]; then
	    return 0
	else
	    rm -f $1
	    return 1
	fi
    else
	return 1
    fi
}

function downloadStep()
{
    STEPSTARTTIME=$(date +%s)
    step=$(printf '%03d' $1)

    if [ "$RESOLUTION" == "0p50" ]; then
	FILE="gfs.t${RT_HOUR}z.pgrb2full.${RESOLUTION}.f${step}"
    else
	FILE="gfs.t${RT_HOUR}z.pgrb2.${RESOLUTION}.f${step}"	
    fi

    if $(testFile ${TMP}/grb/${FILE}); then
	echo "Cached file: $FILE size: $(stat --printf="%s" ${TMP}/grb/${FILE}) messages: $(wgrib2 ${TMP}/grb/${FILE}|wc -l):"
	break;
    else
	while [ 1 ]; do
	    ((count=count+1))
	    echo "Downloading file: $FILE try: $count" 

	    STARTTIME=$(date +%s)
	    curl -s -S -o $TMP/grb/${FILE} "http://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RESOLUTION}.pl?file=${FILE}&lev_100_mb=on&lev_150_mb=on&lev_200_mb=on&lev_250_mb=on&lev_300_mb=on&lev_350_mb=on&lev_400_mb=on&lev_450_mb=on&lev_500_mb=on&lev_550_mb=on&lev_600_mb=on&lev_650_mb=on&lev_700_mb=on&lev_750_mb=on&lev_800_mb=on&lev_850_mb=on&lev_900_mb=on&lev_925_mb=on&lev_950_mb=on&lev_975_mb=on&lev_1000_mb=on&lev_surface=on&lev_2_m_above_ground=on&lev_10_m_above_ground=on&lev_mean_sea_level=on&lev_entire_atmosphere=on&lev_entire_atmosphere_%5C%28considered_as_a_single_layer%5C%29=on&lev_low_cloud_layer=on&lev_middle_cloud_layer=on&lev_high_cloud_layer=on&var_CAPE=on&var_CIN=on&var_GUST=on&var_HGT=on&var_ICEC=on&var_LAND=on&var_PEVPR=on&var_PRATE=on&var_PRES=on&var_PRMSL=on&var_PWAT=on&var_RH=on&var_SHTFL=on&var_SNOD=on&var_SOILW=on&var_SPFH=on&var_TCDC=on&var_TMP=on&var_UGRD=on&var_VGRD=on&var_VVEL=on&subregion=&leftlon=${LEFT}&rightlon=${RIGHT}&toplat=${TOP}&bottomlat=${BOTTOM}&dir=%2Fgfs.${RT_DATE_HH}"
	    ENDTIME=$(date +%s)
	    if $(testFile ${TMP}/grb/${FILE}); then
		echo "Downloaded file: $FILE size: $(stat --printf="%s" ${TMP}/grb/${FILE}) messages: $(wgrib2 ${TMP}/grb/${FILE}|wc -l) time: $(($ENDTIME - $STARTTIME))s wait: $((($ENDTIME - $STEPSTARTTIME) - ($ENDTIME - $STEPSTARTTIME)))s"
		break;
	    fi

            # break if max count
	    if [ $count = 60 ]; then break; fi; 
	    sleep 60
	done # while 1

    fi
}

# Download intervals 
for l in "${INTERVALS[@]}"
do
    echo "Downloading interval $l"
    for i in $(seq $l)
    do
	if [ -n "$DRYRUN" ]; then
	    echo -n "$i "
	else
	    runBacground $i
	fi
    done
    if [ -n "$DRYRUN" ]; then
	echo ""
    fi
done

if [ -n "$DRYRUN" ]; then
    exit
fi

# Wait for the downloads to finish
wait

echo ""
echo "Download size $(du -hs $TMP/grb/|cut -f1) and $(ls -1 $TMP/grb/|wc -l) files."

echo "Converting grib files to qd files..."
gribtoqd -n -d -t -L 1,10,100,101,103,105,200,214,224,234,244 -p "54,GFS Surface,GFS Pressure" -o $TMP/$OUTNAME.sqd $TMP/grb/
mv -f $TMP/$OUTNAME.sqd_levelType_1 $TMP/${OUTNAME}_surface.sqd
mv -f $TMP/$OUTNAME.sqd_levelType_100 $TMP/${OUTNAME}_pressure.sqd

#
# Post process some parameters 
#
echo -n "Calculating parameters: pressure..."
cp -f  $TMP/${OUTNAME}_pressure.sqd $TMP/${OUTNAME}_pressure.sqd.tmp
echo -n "surface..."
qdscript $CNF/gfs-surface.st < $TMP/${OUTNAME}_surface.sqd > $TMP/${OUTNAME}_surface.sqd.tmp
echo "done"

#
# Create querydata totalWind and WeatherAndCloudiness objects
#
echo -n "Creating Wind and Weather objects: pressure..."
qdversionchange -w 0 7 < $TMP/${OUTNAME}_pressure.sqd.tmp > $TMP/${OUTNAME}_pressure.sqd
echo -n "surface..."
qdversionchange -a 7 < $TMP/${OUTNAME}_surface.sqd.tmp > $TMP/${OUTNAME}_surface.sqd
echo "done"

#
# Copy files to SmartMet Workstation and SmartMet Production directories
# Bzipping the output file is disabled until all countries get new SmartMet version
# Pressure level
if [ -s $TMP/${OUTNAME}_pressure.sqd ]; then
    echo -n "Compressing pressure data..."
    bzip2 -k $TMP/${OUTNAME}_pressure.sqd
    echo "done"
    echo -n "Copying file to SmartMet Workstation..."
    mv -f $TMP/${OUTNAME}_pressure.sqd $OUT/pressure/querydata/${OUTNAME}_pressure.sqd
    mv -f $TMP/${OUTNAME}_pressure.sqd.bz2 $EDITOR/
    echo "done"
fi

# Surface
if [ -s $TMP/${OUTNAME}_surface.sqd ]; then
    echo -n "Compressing surface data..."
    bzip2 -k $TMP/${OUTNAME}_surface.sqd
    echo "done"
    echo -n "Copying file to SmartMet Production..."
    mv -f $TMP/${OUTNAME}_surface.sqd $OUT/surface/querydata/${OUTNAME}_surface.sqd
    mv -f $TMP/${OUTNAME}_surface.sqd.bz2 $EDITOR/
    echo "done"
fi

if [ -n "$GRIB_COPY_DEST" ]; then
    rsync -a $TMP/grb/ $GRIB_COPY_DEST
fi

rm -f $TMP/*_gfs_*
rm -f $TMP/grb/gfs*
rmdir $TMP/grb
rmdir $TMP

echo "Created files: ${OUTNAME}_surface.sqd and ${OUTNAME}_surface.sqd"
