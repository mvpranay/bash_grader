init(){
    if [ -f ".remote" ]; then
        echo "Already initialized."
        return
    fi

    # first argument is the remote repository
    if [ -z "$1" ]; then
        echo "Please provide the remote repository."
        return
    fi

    # create the remote repository if it doesn't exist
    if [ ! -d $1 ]; then
        mkdir $1
    fi

    echo $1 > .remote

    : > $1/.git_log
    : > $1/.tracked_files
    : > $1/.curr_commit_id

    echo "Initialized remote repository."

    return
}

# adds a file, once added, the file will be tracked. only the latest version will be considered for all purposes
add(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    # check if the file exists
    if [ ! -f $1 ]; then
        echo "File does not exist."
        return
    fi

    remote=`cat .remote`

    # check if the file is already being tracked
    tracked_files=`cat $remote/.tracked_files`
    if [ ! -z "$tracked_files" ]; then
        out=`cat $remote/.tracked_files | egrep "^$1$"`
        if [ ! -z "$out" ]; then
            echo "File is already being tracked."
            return
        fi
    fi

    # ensure file is a .csv
    if [[ $1 != *".csv" ]]; then
        echo "Only .csv files are allowed."
        return
    fi

    echo $1 >> $remote/.tracked_files

    echo "Added $1 to tracking."
    return
}

log(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    remote=`cat .remote`

    curr_commit_id=`cat $remote/.curr_commit_id`

    sed "/^$curr_commit_id:/s/$/ <--/" "$remote/.git_log"

    return
}

# removes a file. once removed, the file will not be tracked
remove(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    # check if the file exists
    if [ ! -f $1 ]; then
        echo "File does not exist."
        return
    fi

    remote=`cat .remote`

    # check if the file is not being tracked
    out=`cat $remote/.tracked_files | egrep "^$1$"`
    if [ -z $out ]; then
        echo "File is not being tracked."
        return
    fi

    # using grep to pick all the lines except the line containing the file
    cat $remote/.tracked_files | grep -v $1 > .temp
    mv .temp $remote/.tracked_files

    echo "Removed $1 from tracking."
    return
}

status(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    remote=`cat .remote`

    curr_commit_id=`cat $remote/.curr_commit_id`
    latest_commit_id=`tail -n 1 $remote/.git_log | cut -d ":" -f 1`

    # allow to run status only if you are in the latest commit
    if [ ! -z $curr_commit_id ]; then
        if [ $curr_commit_id != $latest_commit_id ]; then
            echo "Please checkout the latest commit before checking status."
            return
        fi
    fi

    declare -A latest_commit_files

    for file in `ls $remote/$latest_commit_id`; do
        latest_commit_files[$file]=1
    done

    declare -A local_files

    for file in `ls | egrep "*\.csv"`; do
        local_files[$file]=1
    done

    # check for new csv files that aren't being tracked
    for file in ${!local_files[@]}; do
        if [[ ! -v latest_commit_files[$file] ]]; then
            if [ -z "`cat $remote/.tracked_files | egrep $file `" ]; then
                echo "New file: $file (untracked)."
            else
                echo "New file: $file (tracked)."
            fi
        fi
    done

    # check for files that are being tracked but are not present
    for file in ${!latest_commit_files[@]}; do
        if [[ ! -v local_files[$file] ]]; then
            echo "Deleted file: $file."
        fi
    done

    # if no commits made yet
    if [ -z $curr_commit_id ]; then
        return
    fi

    old_files=`ls $remote/$curr_commit_id`

    # check if files have been modified
    for file in ${old_files[@]}; do
        if [[ -v local_files[$file] ]]; then
            if [ ! -z "`diff $file $remote/$latest_commit_id/$file`" ]; then
                echo "Modified file: $file."
            fi
        fi
    done

    return
}

# generate a random 16 digit hash id
hash(){
    hash_value=""
    for i in {1..16}; do
        hash_value+=$((${RANDOM}%10))
    done
    echo $hash_value
    return;
}

commit(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    # commit msg is $*
    remote=`cat .remote`

    # allow commit only if you are currently in the latest commit
    curr_commit_id=`cat $remote/.curr_commit_id`
    latest_commit_id=`tail -n 1 $remote/.git_log | cut -d ":" -f 1`

    if [ ! -z $curr_commit_id ]; then
        if [ $curr_commit_id != $latest_commit_id ]; then
            echo "Please checkout the latest commit before committing."
            return
        fi
    fi

    status_msg=`status`

    # check if there are changes to commit
    if [ -z "$status_msg" ]; then
        echo "No changes to commit."
        return
    fi

    # check if the commit msg is empty
    if [ -z "$*" ]; then
        echo "Please provide a commit message."
        return
    fi

    # remove the deleted files from the tracked files
    echo $status_msg | egrep "Deleted file" | cut -d ":" -f 2 > .temp

    if [ -z "cat .temp" ]; then
        :
    else
        : > .temp2

        while read -r line; do
            # line=`echo $line | xargs`
            if [ -z "`cat .temp | egrep $line`" ]; then
                echo $line >> .temp2
            fi
        done < "$remote/.tracked_files"

        mv .temp2 $remote/.tracked_files
    fi
    rm .temp

    # obtain hash id
    hash_id=`hash`

    # create a directory with the hash id
    mkdir $remote/$hash_id

    # copy all the local tracked files to the directory
    while read line; do
        cp $line $remote/$hash_id
    done < "$remote/.tracked_files"

    # write the commit msg to the git log
    echo "$hash_id:$*" >> $remote/.git_log
    echo "$hash_id" > $remote/.curr_commit_id

    echo "Committed with id $hash_id."
    return
}

checkout(){
    # check if mgit has been initialized
    if [ ! -f ".remote" ]; then
        echo "Please initialize mgit first."
        return
    fi

    # commit hash id is $1
    remote=`cat .remote`

    # check if the hash id matches the beginning of exactly one commit id
    num_matches=`cat $remote/.git_log | egrep "^$1" | wc -l`

    if [ $num_matches -eq 0 ]; then
        echo "No such commit id."
        return
    elif [ $num_matches -gt 1 ]; then
        echo "Ambiguous commit id."
        echo "Possible commit ids :"
        cat $remote/.git_log | egrep "^$1" | cut -d ":" -f 1
        return
    fi    

    # obtain the commit id of the commit
    matching_log=`cat $remote/.git_log | egrep "^$1"`
    commit_id=${matching_log%:*}

    # if commit id is the same as the current commit id, do nothing
    if [ $commit_id == `cat $remote/.curr_commit_id` ]; then
        echo "Already at commit $commit_id."
        return
    fi

    # remove the current files in the directory
    rm -f *.csv

    # copy files from the directory to the current directory
    files_in_commit=`ls $remote/$commit_id`

    for file in $files_in_commit; do
        cp $remote/$commit_id/$file .
    done

    # change the curr commit id
    echo $commit_id > $remote/.curr_commit_id

    echo "Checked out commit $commit_id."

    return
}

if [[ $1 == "init" ]]; then 
    init $2
elif [[ $1 == "add" ]]; then
    add $2
elif [[ $1 == "commit" ]]; then
    # obtain commit message properly
    com_msg=$*
    com_msg=${com_msg#commit}
    commit $com_msg
elif [[ $1 == "rm" ]]; then
    remove $2
elif [[ $1 == "status" ]]; then
    status
elif [[ $1 == "checkout" ]]; then
    checkout $2
elif [[ $1 == "log" ]]; then
    log
else
    echo "Invalid command."
fi