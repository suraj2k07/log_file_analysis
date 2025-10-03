declare -A mondic=(
    ["Jan"]=0 ["Feb"]=1 ["Mar"]=2 ["Apr"]=3 ["May"]=4 ["Jun"]=5
    ["Jul"]=6 ["Aug"]=7 ["Sep"]=8 ["Oct"]=9 ["Nov"]=10 ["Dec"]=11
)
timecompare() { # function for comparing timestamps, returns 0 if 2nd argument is earlier than 1st argument
    if [[ $2 == "" ]]; then
        echo "False"
        return 1
    fi
    list1=($1)
    list2=($2)
    if (( 10#${list2[3]} > 10#${list1[3]} )); then echo "False"; return 1; fi
    if (( 10#${list2[3]} < 10#${list1[3]} )); then echo "True"; return 0; fi
    if (( ${mondic[${list2[0]}]} > ${mondic[${list1[0]}]} )); then echo "False"; return 1; fi
    if (( ${mondic[${list2[0]}]} < ${mondic[${list1[0]}]} )); then echo "True"; return 0; fi
    if (( 10#${list2[1]} > 10#${list1[1]} )); then echo "False"; return 1; fi
    if (( 10#${list2[1]} < 10#${list1[1]} )); then echo "True"; return 0; fi
    res2=($(echo "${list2[2]}" | sed 's/:/ /g'))
    res1=($(echo "${list1[2]}" | sed 's/:/ /g'))
    if (( 10#${res2[0]} > 10#${res1[0]} )); then echo "False"; return 1; fi
    if (( 10#${res2[0]} < 10#${res1[0]} )); then echo "True"; return 0; fi
    if (( 10#${res2[1]} > 10#${res1[1]} )); then echo "False"; return 1; fi
    if (( 10#${res2[1]} < 10#${res1[1]} )); then echo "True"; return 0; fi # 10# is to tell the base is 10
    if (( 10#${res2[2]} > 10#${res1[2]} )); then echo "False"; return 1; fi
    if (( 10#${res2[2]} < 10#${res1[2]} )); then echo "True"; return 0; fi
    echo "True"
    return 0
}
st_date=$1
en_date=$2
match="False"
regex='^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}$'
if [[ "$st_date" == "empty" ]] && [[ "$en_date" == "empty" ]]; then  # if both are empty then true
st_date=""
en_date=""
match="True"
fi
if [[ "$en_date" == "empty" ]] && [[ $st_date =~ $regex ]]; then
match="True"
fi

if [[ $st_date =~ $regex ]] && [[ $en_date =~ $regex ]]; then
hik=$(timecompare "$en_date" "$st_date") # if end date is earlier than start date then false
ak=$?
match="False"
if (( ak == 0 )); then
    match="True"
fi
fi
if [[ "$match" == "False" ]]; then
    exit 1
fi
filename=$3
name=$4
file="UPLOADS_FOLDER/$filename"
string="Timestamp,Level,Component,EventId,Event Template\n"
declare -a dic_keys
declare -a dic_values
declare -a pidic_keys
declare -a pidic_values
declare -a badic_keys
declare -a badic_values
present="False"
if [ -f "$file" ]; then
    while read line || [[ -n "$line" ]] ; do
        res2=$(echo "$line" | cut -d',' -f1)
        res3=$(echo "$res2" | sed -E 's/([A-Za-z]{3} )//1')
        res4=$(echo "$line" | cut -d',' -f2)
        res5=$(echo "$line" | cut -d',' -f4)
        hi1=$(timecompare "$res3" "$st_date")
        a1=$?
        if [[ "$en_date" != "empty" ]]; then
            hi2=$(timecompare "$en_date" "$res3")
            a2=$?
        else
            a2=0
        fi
    if [[ -z "$st_date" ]] || { (( a1 == 0 )) && (( a2 == 0 )); }; then
            present="True"
            if [[ "$name" == "table" ]]; then # if this is only for a table then we just need string
                string+="$line\n"
            elif [[ "$name" != "table" ]]; then
                found="false"
                for i in "${!dic_keys[@]}"; do
                    if [[ "${dic_keys[$i]}" == "$res3" ]]; then
                        ((dic_values[$i]++))
                        found="true"
                        break
                    fi
                done
                if [[ "$found" == "false" ]]; then
                    dic_keys+=("$res3")
                    dic_values+=(1)
                fi
                found="false"
                for i in "${!pidic_keys[@]}"; do
                    if [[ "${pidic_keys[$i]}" == "$res4" ]]; then
                        ((pidic_values[$i]++))
                        found="true"
                        break
                    fi
                done
                if [[ "$found" == "false" ]]; then
                    pidic_keys+=("$res4")
                    pidic_values+=(1)
                fi
                found="false"
                for i in "${!badic_keys[@]}"; do
                    if [[ "${badic_keys[$i]}" == "$res5" ]]; then
                        ((badic_values[$i]++))
                        found="true"
                        break
                    fi
                done
                if [[ "$found" == "false" ]]; then
                    badic_keys+=("$res5")
                    badic_values+=(1)
                fi
            fi
        elif [[ $present == "True" ]] ; then
            break
        fi
    done < <(tail -n +2 "$file")
fi
if [[ "$name" == "table" ]]; then 
    echo -e $string > "UPLOADS_FOLDER/time_filter.csv"
elif [[ "$name" != "table" ]]; then
    listli1=""
    listli2=""
    for i in "${!dic_keys[@]}"; do
        listli1+="${dic_keys[$i]},"
        listli2+="${dic_values[$i]},"
    done
    listpi1=""
    listpi2=""
    for i in "${!pidic_keys[@]}"; do
        listpi1+="${pidic_keys[$i]},"
        listpi2+="${pidic_values[$i]},"
    done

    listba1=""
    listba2=""
    for i in "${!badic_keys[@]}"; do
        listba1+="${badic_keys[$i]},"
        listba2+="${badic_values[$i]},"
    done
    python3 plot.py "$listli1" "$listli2" "$listpi1" "$listpi2" "$listba1" "$listba2" #run the python file to generate plot.
fi