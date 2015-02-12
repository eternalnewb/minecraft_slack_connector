#!/bin/sh

# Reset all variables that might be set
file=
verbose=0

# Usage Info
show_help() {
cat << EOF

Usage: ${0##*/} [-h] | -f path to config file 
-l and -u will override the config file

	-h		Display this help and exit
	-f		path to config file

EOF
}

# Argument Parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        -f|--file)   
            if [ "$#" -gt 1 ]; then
                file=$2
                shift 2
                continue
            else
                echo 'ERROR: Must specify a non-empty "--file FILE" argument.' >&2
                exit 1
            fi
            ;;
        --file=?*)
            file=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --file=)         # Handle the case of an empty --file=
            echo 'ERROR: Must specify a non-empty "--file FILE" argument.' >&2
            exit 1
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift #increment the argument number??!
done

# --file is a required option. Check that it has been set.
if [ ! "$file" ]; then
    echo 'ERROR: option "--file FILE" not given. See --help.' >&2
    exit 1
fi



#Push Minecraft Joins & Parts to Slack via webhook API


# Another way to ctrl-c out of the while loop because idk what im doing
cleanup ()
{
kill -s SIGTERM $!
exit 0
}
trap cleanup SIGINT SIGTERM

# Read config
source $file
# Provides: 
# $WEBHOOK_URL
# $SLACK_CHANNEL
# $BOT_NAME
# $ICON_EMOJI
# $MINECRAFT_SERVER_LOG_FILE

while true; do
  # Watcher.py is a way to avoid futzing with inotify.
  # https://bitbucket.org/denilsonsa/small_scripts/src/b20d762b9c1a0d250ddbd8e26850df62d84b1559/sleep_until_modified.py?at=default

  ./watcher.py MINECRAFT_SERVER_LOG_FILE
  MSG=`tail -n2 MINECRAFT_SERVER_LOG_FILE | grep 'left\|joined\|to \|was \|blew\|died\|fell\|ground\|drowned\|slain\|flames\|lava\|wall' | sed 's/^.*] //'`;
  echo $MSG;

	#todo turn this into a variable in the script instead of a file
  if [[ $MSG == $(cat last_slack) ]]; then echo "Duplicate message detected: $MSG"; continue; fi

  THIS_HOOK='"payload={"channel": "'$SLACK_CHANNEL'", "username": "'$BOT_NAME\
  '", "text": "'$MSG'", "icon_emoji": "'$ICON_EMOJI'"}"';
  
  curl -X POST --data-urlencode "$THIS_HOOK" "$WEBHOOK_URL"

#   THIS_HOOK="$THIS_HOOK$SLACK_CHANNEL"
#   THIS_HOOK='$THIS_HOOK", "username": "'
#   THIS_HOOK="$THIS_HOOK$BOT_NAME"
#   THIS_HOOK='", "text": "'
#   curl -X POST --data-urlencode "payload={\"channel\": \"#minecraft\", \"username\": \"minecraft.whatever.com:443\", \"text\": \"$MSG\", \"icon_emoji\": \":tekkit:\"}" $WEBHOOK_URL;
   echo "$MSG" > last_slack

