# !/bin/bash

# remove main if already existing
rm -f main.csv 2> /dev/null

# get all csv files
files=(*.csv)

# declare associative array to store records where key is RollNo and value is "filename:marks filename:marks filename:marks"
declare -A marks
# RollNo to Name
declare -A names

for file in ${files[@]}
do
    # go through all records in that file and add data to marks and names
    let line_num=0
    while read -r line
    do
        # ignore first line containing format of data
        let line_num++
        if [ $line_num -eq 1 ]
        then
            continue
        fi
        # get roll no, name and update marks and names
        rollno=$(echo $line | cut -d, -f1)
        # convert roll no to lowercase
        rollno=$(echo $rollno | sed -E "s/([A-z0-9]*)/\L\1/g")
        name=$(echo $line | cut -d, -f2)
        mark=$(echo $line | cut -d, -f3)
        marks[$rollno]+=" $file:$mark"
        names[$rollno]=$name
    done < $file
done

# get file names without csv and add it to suffix
suffix=""
for file in ${files[@]}
do
    file_name=${file%.csv}
    suffix+=",$file_name"
done

# write to main.csv
echo "RollNo,Name$suffix" > main.csv

for rollno in ${!marks[@]}
do
    # get name and marks
    name=${names[$rollno]}
    marks_string=${marks[$rollno]}
    marks_arr=($marks_string)

    content="$rollno,$name"
    for file in ${files[@]}
    do
        # check if marks_arr has that file's marks
        found=0
        for item in ${marks_arr[@]}
        do
            file_name=${item%:*}
            if [[ $file_name == $file ]]
            then
                found=1
                content+=","${item#*:}
                break
            fi
        done
        if [[ $found -eq 0 ]]
        then
            content+=",a"
        fi
    done
    echo $content >> main.csv
done
