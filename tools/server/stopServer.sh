#!/bin/bash

mcrconPort=5050
mcrconPasswd="passwd"
mcChatColor="blue"

counter=60

# arg parsing
positionalArgs=()
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
			positionalArgs+=("$1") # save positional arg
			shift # past argument
		  ;;
	esac
done

say () {
	echo $*
	mcrcon mcrcon -P $mcrconPort -p $mcrconPasswd \
	'tellraw @a {"text":"'"$*"'","color":"$mcChatColor"}'
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