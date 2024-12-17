# !/bin/bash

upload(){
    file=$1
    cp $file . 
}

# commands can be upload, combine, total, update
if [[ $1 == "upload" ]]; then
    upload $2
elif [[ $1 == "combine" ]]; then
    bash combine.sh
elif [[ $1 == "total" ]]; then
    bash total.sh
elif [[ $1 == "update" ]]; then
    bash update.sh
else
    echo "Invalid command."
fi

