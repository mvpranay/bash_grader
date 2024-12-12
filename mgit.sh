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

    echo $1 > .remote

    : > $1/.git_log
    : > $1/.tracked_files
    : > $1/.curr_commit_id

    echo "Initialized remote repository."

    return
}

# adds a file, once added, the file will be tracked. only the latest version will be considered for all purposes
add(){
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

# removes a file. once removed, the file will not be tracked
rm(){
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
    # grep -v $1 $tracked_files > .temp
    cat $remote/.tracked_files | grep -v $1 > .temp
    mv .temp $remote/.tracked_files

    echo "Removed $1 from tracking."
    return
}

status(){

    declare -A tracked_files

    remote=`cat .remote`

    while read line; do
        tracked_files[$line]=1
    done < "$remote/.tracked_files"

    declare -A local_files

    for file in `ls | egrep "*\.csv"`; do
        local_files[$file]=1
    done

    # check for new csv files that aren't being tracked
    for file in ${!local_files[@]}; do
        if [[ ! -v ${tracked_files[$file]} ]]; then
            echo "New file: $file"
        fi
    done

    # check for files that are being tracked but are not present
    for file in ${!tracked_files[@]}; do
        if [[ ! -v ${local_files[$file]} ]]; then
            continue
        else
            echo "Deleted file: $file"
        fi
    done

    # obtain the latest commit id
    latest_commit=`tail -n 1 $remote/.git_log`
    # strip the : and commit msg as the line is in the format <commit_id>:<commit_msg>
    latest_commit_id=${latest_commit%:*}

    # check if files have been modified
    for file in ${!tracked_files[@]}; do
        if [[ -v ${local_files[$file]} ]]; then
            if [ ! -z `diff $file $remote/$latest_commit_id/$file` ]; then
                echo "Modified file: $file"
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
    # commit msg is $*

    # check if there are changes to commit
    if [ -z "`status`" ]; then
        echo "No changes to commit"
        return
    fi

    # check if the commit msg is empty
    if [ -z "$*" ]; then
        echo "Please provide a commit message"
        return
    fi

    remote=`cat .remote`

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

    echo "Committed with id $hash_id"
    return
}

checkout(){
    # ensure there are no changes after the latest commit
    if [ ! -z `status` ]; then
        echo "Changes made after latest commit."
        echo "Commit changes before checking out a commit."
        return
    fi

    # commit hash id is $1
    remote=`cat .remote`

    # check if the hash id matches the beginning of exactly one commit id
    num_matches=`cat $remote/.git_log | egrep "^$1" | wc -l`

    if [ $num_matches -eq 0]; then
        echo "No such commit id"
        return
    elif [ $num_matches -gt 1 ]; then
        echo "Ambiguous commit id"
        return
    fi    

    # remove the current files 
    curr_commit_id=`cat $remote/.curr_commit_id`
    current_files=`ls $remote/$curr_commit_id`

    for file in $current_files; do
        rm $file
    done

    # obtain the commit id of the commit
    matching_log=`cat $remote/.git_log | egrep $1`
    commit_id=${matching_log%:*}

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
    rm $2
elif [[ $1 == "status" ]]; then
    status
elif [[ $1 == "checkout" ]]; then
    checkout $2
else
    echo "Invalid command."
fi