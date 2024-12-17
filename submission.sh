# !/bin/bash

upload(){
    file=$1
    cp $file . 
}

# commands can be upload, combine, total, update, git_init, git_add, git_rm, git_status, git_commit, git_checkout, git_log
if [[ $1 == "upload" ]]; then
    upload $2
elif [[ $1 == "combine" ]]; then
    bash combine.sh
elif [[ $1 == "total" ]]; then
    bash total.sh
elif [[ $1 == "update" ]]; then
    bash update.sh
elif [[ $1 == "git_init" ]]; then
    bash mgit.sh init $2
elif [[ $1 == "git_add" ]]; then
    bash mgit.sh add $2
elif [[ $1 == "git_rm" ]]; then
    bash mgit.sh rm $2
elif [[ $1 == "git_status" ]]; then
    bash mgit.sh status
elif [[ $1 == "git_commit" ]]; then
    # obtain commit message properly
    com_msg=$*
    com_msg=${com_msg#git_commit}
    bash mgit.sh commit $com_msg
elif [[ $1 == "git_checkout" ]]; then
    bash mgit.sh checkout $2
elif [[ $1 == "git_log" ]]; then
    bash mgit.sh log
else
    echo "Invalid command."
fi

