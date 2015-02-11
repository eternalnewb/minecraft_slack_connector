#!/bin/sh

# Reset all variables that might be set
file=
verbose=0

# Usage Info
show_help() {
cat << EOF

Usage: ${0##*/} [-h] -l /path/to/server.log -u slackWebhookURL | -f path to config file 
-l and -u will override the config file

	-h		Display this help and exit
	-l | --logfile 	Path to your minecraft server.log file. Assumed
			to be ../server.log if unsupplied
	-u | --URL	URL notifications will be posted to
	-f		path to config file holding -l and -u's data

EOF
}

# Argument Parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
            show_help
            exit
            ;;
        -f|--file)       # Takes an option argument, ensuring it has been specified.
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
        -v|--verbose)
            verbose=$((verbose + 1)) # Each -v argument adds 1 to verbosity.
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

# Suppose --file is a required option. Check that it has been set.
if [ ! "$file" ]; then
    echo 'ERROR: option "--file FILE" not given. See --help.' >&2
    exit 1
fi



#Push Minecraft Joins & Parts to Slack via webhook API

WEBHOOK_URL=''

# Another way to ctrl-c out of the while loop because idk what im doing
cleanup ()
{
kill -s SIGTERM $!
exit 0
}
trap cleanup SIGINT SIGTERM


while true; do
  # Watcher.py is a way to avoid futzing with inotify.
  # https://bitbucket.org/denilsonsa/small_scripts/src/b20d762b9c1a0d250ddbd8e26850df62d84b1559/sleep_until_modified.py?at=default
  # server.log is your minecraft server.log file, will work in vanilla & most modpacks

  ./watcher.py /opt/tekkit/server.log
  MSG=`tail -n2 server.log | grep 'left\|joined\|to \|was \|blew\|died\|fell\|ground\|drowned\|slain\|flames\|lava\|wall' | sed 's/^.*] //'`;
  echo $MSG;

  if [[ $MSG == $(cat last_slack) ]]; then echo "Duplicate message detected: $MSG"; continue; fi

  curl -X POST --data-urlencode "payload={\"channel\": \"#minecraft\", \"username\": \"minecraft.whatever.com:443\", \"text\": \"$MSG\", \"icon_emoji\": \":tekkit:\"}" $WEBHOOK_URL;
  echo "$MSG" > last_slack

