# !/bin/bash

# take input as to what exam to update
echo -n "Enter the exam to update :"

# read the exam name
read EXAM_NAME
file_name=${EXAM_NAME}.csv

# function to handle exits
function finish(){
    rm -f .temp 2> /dev/null
    exit 0
}

# check if file exists
if [[ ! -f $file_name ]]
then
    echo "Exam does not exist!"
    finish
fi

# take rollno as input
echo -n "Enter the roll number of student :"
read ROLLNO
ROLL_LOWERCASE=$(echo $ROLLNO | sed -E "s/([A-za-z0-9]*)/\L\1/g")

# take name as input
echo -n "Enter the name of student :"
read NAME
NAME_LOWERCASE=$(echo $NAME | sed -E "s/([A-z0-9]*)/\L\1/g")

# read updated marks from user
echo -n "Enter the updated marks :"
read UPDATED_MARKS

# update marks in the original file if possible
found=0

file=$(cat $file_name)
for line in $file
do
    line=$(echo $line | tr , ' ')
    line=($line)
    rollno=${line[0]}
    # check for lowercase of rollno
    roll_lower=$(echo $rollno | sed -E "s/([A-z0-9]*)/\L\1/g")
    name=${line[1]}
    name_lowercase=$(echo $name | sed -E "s/([A-z0-9]*)/\L\1/g")
    marks=${line[2]}

    # if rollno matches, check if name matches
    if [[ $roll_lower == $ROLL_LOWERCASE ]]
    then
        if [[ $name_lowercase = $NAME_LOWERCASE ]]
        then
            found=1
            echo "$rollno,$name,$UPDATED_MARKS" >> .temp
        else
            echo "Name does not match!"
            echo "Records show name as $name with roll no $rollno"
            echo "Would you like to update that record?[y/n]"

            # read user input (not working)
            read ans
            
            if [ $ans == "y" ]
            then
                found=1
                echo "$rollno,$name,$UPDATED_MARKS" >> .temp
            else
                echo "Record not updated, terminating!"
                finish
            fi
        fi
    else
        echo $rollno,$name,$marks >> .temp
    fi
done

# if rollno not found, ask user if they want to add a new record or just ignore
if [[ $found -eq 0 ]]
then
    echo "Roll number not found!"
    echo "Would you like to add a new record?[y/n]"
    read ans
    if [ $ans == "y" ]
    then
        echo "$ROLLNO,$NAME,$UPDATED_MARKS" >> .temp
    else
        echo "Record not added, terminating!"
        finish
    fi
fi
 
# move contents of .temp to the file
mv .temp $file_name
