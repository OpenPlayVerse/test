#!/bin/bash

counter=60


# arg parsing
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--seconds)    
            counter=$2
            shift
            shift  
        ;;
        -m|--minutes)    
            counter=$(($2 * 60))
            shift
            shift  
        ;;
        -d|--dry)
            dryRun=true
            shift
        ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
        ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
          ;;
    esac
done

say () {
    echo $*
    mcrcon mcrcon -P 5050 -p 'passwd' \
    'tellraw @a {"text":"'"$*"'","color":"blue"}'
}

while [ $counter -ge 0 ]; do
    if [ $(expr $counter % 60) -eq 0 ] && [ $counter -gt 0 ]; then
        say "Server is about to restart for an pack update in $(expr $counter / 60 ) minute(s)" 
    elif [ $counter -eq 30 ]; then
        say "Server is about to restart for an pack update in $counter seconds" 
    elif [ $counter -eq 10 ]; then
        say "Server is about to restart for an pack update in $counter seconds" 
    elif [ $counter -lt 10 ]; then
        say "Server restart in $counter"
    fi
    let "counter=counter-1"
done

if $dryRun; then
    say "Dry run"
    echo "Done"
    exit 0
fi