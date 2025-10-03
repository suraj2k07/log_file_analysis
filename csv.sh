#!/bin/bash
ifile=$1

output_file="UPLOADS_FOLDER/output.csv"
output1_file="UPLOADS_FOLDER/notice.csv"
output2_file="UPLOADS_FOLDER/error.csv"
output3_file="UPLOADS_FOLDER/table_filter.csv"
output4_file="UPLOADS_FOLDER/time_filter.csv"


touch $output_file
touch $output1_file
touch $output2_file
touch $output3_file
touch $output4_file

echo "Timestamp,Level,Component,EventId,Event Template" > $output_file
echo "Timestamp,Level,Component,EventId,Event Template" > $output1_file
echo "Timestamp,Level,Component,EventId,Event Template" > $output2_file

boo=$(awk '
BEGIN { FS="[][]"; 
RS="\n";
ogfile="True";}
NF <= 7 {
    if (ogfile=="False") {print("False"); exit 1;}
    if (!( $2 ~ /[A-Za-z]{3} [A-Za-z]{3} [0-3][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/ && ($4 ~ /notice/ || $4 ~ /error/ ))) {ogfile="False" }
    if ($5 ~ /jk2_init\(\) Found child.*/) {print($2","$4","substr($5,2,length($5)-2)",E1,jk2_init() Found child <*> in scoreboard slot <*>") >> "'"$output_file"'";}   
    else if ($5 ~ /workerEnv\.init\(\) ok.*/) {print($2","$4","substr($5,2,length($5)-2)",E2,workerEnv.init() ok <*>") >> "'"$output_file"'";}
    else if ($5 ~ /mod_jk child workerEnv in error state.*/) {print($2","$4","substr($5,2,length($5)-2)",E3,mod_jk child workerEnv in error state <*>") >> "'"$output_file"'";}
    else if ($5 ~ /jk2_init\(\) Can.t find child .*/) {print($2","$4","substr($5,2,length($5)-2)",E5,jk2_init() Can.t find child in scoreboard") >> "'"$output_file"'";}
    else if ($5 ~ /mod_jk child init.*/) {print($2","$4","substr($5,2,length($5)-2)",E6,mod_jk child init <*> <*>") >> "'"$output_file"'";}
    else if ($6 ~ /client .*/) {print($2","$4",["substr($6,1,length($6)-2)"]"substr($7,1,length($7)-2)",E4,[client <*>] Directory index forbidden by rule: <*>") >> "'"$output_file"'";}
    else {ogfile="False"; print("False"); exit 1; }
}
END{
 print (ogfile) 
}' "$ifile")
if [ $? -ne 0 ]; then
    exit 1
fi
awk '
/notice/ {
    print $0 >> "'"$output1_file"'";
}
/error/ {
    print $0 >> "'"$output2_file"'";
}' "$output_file"
if [ "$boo" == "False" ]; then
  exit 1
fi