#!/bin/bash
 
 ROOT="$(dirname "$0")"
 source $ROOT/sources/extra.sh
 
 
function show_help 
 { 
 	c_print "Green" "This script converts PCAP to Netflow data used by the NetShare paper!"
 	c_print "Bold" "Example: sudo ./pcap_to_netshare_flowdata.sh -i example.pcap -o output_dir/ [-n <EXTRA_NFPCAPD_ARG>] "
 	c_print "Bold" "\t\t-i <INPUT_PCAP>: the PCAP to be converted."
	c_print "Bold" "\t\t-o <OUTPUT_DIR>: the OUTPUT DIRECTORY to save all files (Default: output_DATE)"
	c_print "Bold" "\t\t-n <EXTRA_NFPCAPD_ARG>: any additional argument ("key value") you want to add for nfpcapd, e.g., -t 100000 (for timeframe of one file) (Default: None)"
 	exit
 }

PCAP=""
OUTPUT_DIR=""
EXTRA_NFPCAPD_ARG=""

while getopts "h?i:o:n:" opt
do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	i)
 		PCAP=$OPTARG
 		;;
	o)
		OUTPUT_DIR=$OPTARG
		;;
	n)
		EXTRA_NFPCAPD_ARG=$OPTARG
		;;
 	*)
 		show_help
 		;;
	esac
done


if [ -z $PCAP ]
then
	c_print "Red" "Undefined arguments!"
	show_help
fi

#checking required utilities
c_print "White" "Checking required tools (nfpcapd/nfdump)..." 1
requirement_installed=$(which nfpcapd)
retval=$(echo $?)
check_retval $retval

c_print "White" "Creating OUTPUT_DIR ${OUTPUT_DIR}..." 1
mkdir -p $OUTPUT_DIR
retval=$(echo $?)
check_retval $retval

c_print "White" "Generating temporary nfcap files..."
nfpcapd -r $PCAP -l $OUTPUT_DIR $EXTRA_NFPCAPD_ARG
c_print "BGreen" "nfcap files are ready"

#remove path parts
PCAP_BASENAME=${PCAP##*/}
#remove extension
PCAP_BASENAME=${PCAP_BASENAME%.*}

# exit -1
c_print "White" "Converting nfcap files into CSV..." 1
#rm $OUTPUT_DIR/$PCAP.csv > /dev/null #remove any existing file with the same name
#create nfdump csv header - nfdump: Version: NSEL-NEL1.6.23
header="ts,te,td,sa,da,sp,dp,pr,flg,fwd,stos,ipkt,ibyt,opkt,obyt,in,out,sas,das,smk,dmk,dtos,dir,nh,nhb,svln,dvln,ismc,odmc,idmc,osmc,mpls1,mpls2,mpls3,mpls4,mpls5,mpls6,mpls7,mpls8,mpls9,mpls10,cl,sl,al,ra,eng,exid,tr"
#we write this header into the result file manually as results are extracted without header and footer
echo $header > $OUTPUT_DIR/$PCAP_BASENAME.csv
for nfcap in $(ls $OUTPUT_DIR/nfcapd.*)
do
	c_print "White" "\nProcessing file: ${nfcap}..." 1
	nfdump -o csv -q -r $nfcap >> $OUTPUT_DIR/$PCAP_BASENAME.csv
	retval=$(echo $?)
	check_retval $retval
done
#print out DONE :)
# check_retval 0


#do further refinement with python
c_print "White" "Further refinement via Python..." 1
python3 sources/csv_refine.py  -i $OUTPUT_DIR/$PCAP_BASENAME.csv -o $OUTPUT_DIR/$PCAP_BASENAME.final.csv
retval=$(echo $?)
check_retval $retval


c_print "Green" "CSV files are generated in $OUTPUT_DIR directory"

echo ""


