# !/bin/bash

# run combine before running total
bash combine.sh

# read main.csv
let line_num=0
while read -r line
do
    # for first line 
    let line_num++
    if [[ $line_num -eq 1 ]]
    then
        echo $line,total > .main_total.csv
        continue
    fi
    
    line_space_delim=(`echo $line | tr ',' ' '`)
    rollno=${line_space_delim[0]}
    name=${line_space_delim[1]}
    marks=(${line_space_delim[@]:2})
    let total=0
    for mark in ${marks[@]}
    do
        if [[ ! $mark = "a" ]] 
        then
            let total+=$mark
        fi
    done
    echo $line,$total >> .main_total.csv
done < main.csv

# move contents in .main_total.csv to main.csv
mv .main_total.csv main.csv
