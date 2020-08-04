### Functions specific to the configuration and use of a nodeholder

##################################################################
# nodeholder- collection of shell functions for remote
# DEPLOYMENT
# CONFIGURATION
# PORTMAPPINGS
# MANAGEMENT
# MONITORING
# BACKUP
##################################################################

nodeholder-config(){
  
  local ip="$1";
  local config_file="$2";

  # copy config.sh to the remote machine
  scp "$config_file" root@"$ip":"$config_file"
 
  # location where daemonize is on mother node
  local dpath_local="/home/admin/src/daemonize/daemonize";
  
  # location for daemonize on child node
  local dpath_remote="/bin/daemonize";

  # copy daemonize to the remote machine
  scp "$dpath_local" root@"$ip":"$dpath_remote"

  # source configuration and configure machine
  ssh root@"$ip" '
      source "'$config_file'" && config-init
      echo "Deploy \"from a distance\" application with admin.sh"
      echo "--or--"
      echo "Log in to remote host"
      echo "local> dotool-login <droplet>"
  '
  
  # instruct user on next steps
  echo "
  Setup application with admin- from local machine to remote host
  --or--
  Log in to remote host with 'dotool-login <droplet>'
  "
}

nodeholder-install-admin() {
  # ip of node to send file to
  local ip="$1";
  
  # Adds admin.sh to .bashrc
  local statement="\nif [ -f ~/admin.sh ]; then\n  . ~/admin.sh\nfi";

  # file to send to node
  local admin_file="$2";
  
  # send admin file
  scp "$admin_file" admin@"$ip":~/admin.sh
  # specify the role of the node in the admin.sh file
  # and set up .bashrc to source admin.sh on boot/use
  ssh admin@"$ip" \
    'echo "NODEHOLDER_ROLE=child" >> ~/admin.sh && echo -e "'$statement'" >> ~/.bashrc'
  # copy buildpak to node
  scp -r ./api/buildpak admin@"$ip":~/
}

nodeholder-generate-aliases() {

  # source variables into environment
  source ./nodeholder.list

  # create or refresh the aliases file
  echo "" > ./aliases.sh
  
  # collect the names of the servers
  local node_names=($(awk -F"=" '{print $1}' < ./nodeholder.list))

  for name in "${node_names[@]}"; do
	
	# dereference the name of the env var to get the ip
	local ip="${!name}"

	# ready the template
  	local template=$(cat ./aliases.template)
	# inject the name of the server into the template
	template=${template//NAME/"$name"}
	# inject the server's ip into the template
	template=${template//IP/"$ip"}
	# place that template into the aliases file
	echo "$template" >> ./aliases.sh
  done

  # source the aliases into the environment
  source ./aliases.sh
}

nodeholder-refresh-admin() {
  local ip="$1"
  local admin_file="$2"
  scp "$admin_file" admin@"$ip":~/admin.sh
}

nodeholder-remove-node() {
  local ip="$1";
  local node_name="$2";

  ssh admin@"$ip" 'source admin.sh && admin-remove-node "'$node_name'"'

  ## This needs to be in /var or somewhere similar
  ## rm -rf ./apps/$node_name
}

nodeholder-create-node() {
  ## admin vs api
  ## does admin create the nodes and api run the processes?
  ## what's the distinction?

  local ip="$1";
  local node_name="$2";

  ssh admin@"$ip" 'source admin.sh && admin-create-node "'$node_name'"'

  ## This needs to be in /var or somewhere similar
  ## mkdir -p apps/$node_name
}

### EXPERIMENTAL ###
### Everything below this line is experimental ###

#nodeholder-test() {

## cannot parse combined flags like -lk, must be separated -l -k
## nodeholder-test -C doX key -l breaks

#  while [ ! $# -eq 0 ]
#    do
#      case "$1" in
#	      --help|-h) echo "help menu" ;;
#	      --list|-l) dotool-list ;;
#	      --keys|-k) dotool-keys ;;
#	      --delete|-D) dotool-delete "$2" ;;
#	      --create|-C) dotool-create "$2" "$3" "$4" ;;
#      esac
#      shift
#    done

  #local args=($@);
  #local pointer=0;
  #while [ ! $# -eq 0 ]
  #  do
  #    echo "${args[pointer]}"
  #    pointer=$(expr $pointer + 1);
  #    shift
  #  done
#}

nodeholder() {

  REMOTE_USER="root";
  REMOTE_NODE="";

## POSITIVES
## can parse combined flags like -lk

## ISSUES
## flags fire at the same time. -C -c can't be used at the same time
## issue when a third arg isn't provided to -C and a second flag is used


  for arg in "$@"; do
    shift
    case "$arg" in
	    "--keys") set -- "$@" "-k" ;;
	    "--test") set -- "$@" "-t" ;;
	    "--list-nodes"|"--list") set -- "$@" "-l" ;;
	    "--create") set -- "$@" "-C" ;;
	    "--set-remote-node") set -- "$@" "-n" ;;
	    "--login") set "$@" "-L" ;;
	    "--help") set -- "$@" "-h" ;;
	    "--config-with") set -- "$@" "-c" ;;
	    "--set-admin-with") set -- "$@" "-a" ;;
	    "--delete") set -- "$@" "-D" ;;
	    *) set -- "$@" "$arg" ;;
    esac
  done

  OPTIND=1
  while getopts "hlkt:C:n:D:c:a:L:" option; do
    case $option in
	"t")
	  shift 
	  local test_args=($@);
	  local cmd="${test_args[0]}";
	  local should_be="${test_args[1]}";
	  echo "cmd: $cmd, shouldbe: $should_be"
	  ;;
  	"k") dotool-keys ;;
	"l") dotool-list ;;
	"n") 
	  local node_name="$OPTARG";
          REMOTE_NODE=$(dotool-name-to-ip "$node_name");
	  echo "nodeholder is set to communicate with $node_name($REMOTE_NODE)"
	  ;;
  	"c") 
	  local config_file="$OPTARG";
          scp "$config_file" root@"$REMOTE_NODE":"$config_file"
	  echo "Sending $config_file to root@$REMOTE_NODE"
	  
	  # location where daemonize is on mother node
          local dpath_local="/home/admin/src/daemonize/daemonize";
	  
	  # location for daemonize on child node
	  local dpath_remote="/bin/daemonize";
	  
	  # copy daemonize to the remote machine
	  scp "$dpath_local" root@"$REMOTE_NODE":"$dpath_remote"

	  ssh root@"$REMOTE_NODE" '
	      source "'$config_file'" && config-init
	      echo "Deploy \"from a distance\" application with admin.sh"
	      echo "--or--"
	      echo "Log in to remote host"
	      echo "local> dotool-login <droplet>"
	  '
          ;;
        "a") 
	  echo "Sending $OPTARG to $node_name ($ip_addr)"
	  ;;
        "D") dotool-delete "$OPTARG" ;;
	"C")
	  shift
	  set -f
	  IFS=" "
	  local creation_args=($@);
          local host="${creation_args[0]}";
	  local key="${creation_args[1]}";
	  local image_arg="${creation_args[2]}";
	  local image=${image_arg:-ubuntu-18-04-x64};

	  echo "host:$host, key:$key, image:$image"

  	  dotool-create $host $key $image

	  ## need to check that server is up before continuing forward
	  ## host won't be found because the server won't be ready
	  ## by the time this runs
	  REMOTE_NODE=$(dotool-name-to-ip "$host");
	  echo "$host has been created at ip: $REMOTE_NODE"
          echo "nodeholder is set to communicate with $host($REMOTE_NODE)"
	  ;;
  	"L") echo "This is for login" ;;
	"h") echo "Help menu" ;;
  	"?") echo "Incorrect option $arg" ;;
    esac
  done
  shift $(expr $OPTIND - 1) # remove options from positional parameters
}
