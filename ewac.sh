#!/bin/bash

config_path="$HOME/.config/ewac"
argument_regex='^([A-Za-z0-9_]+):[[:space:]]*([A-Za-z0-9_.:-]+)$'
declare -a servers

print_help()
{
  printf "\nManages SSH server connections\n\n"
  printf "Usage:\n"
  printf "  ewac -a <server name> [--local-tunnel=<arg>|--remote-tunnel=<arg>]\n"
  printf "  ewac -c <server name> [--username=<arg>]\n"
  printf "  ewac -d <server name> [--tunnel=<arg>]\n"
  printf "  ewac -l [server name]\n\n"
  printf "Options:\n"
  printf "%-5s%-22s%s\n" " -a" "--add" "add a new server"
  printf "%-5s%-22s%s\n" "" "--local-tunnel=<arg>" "add a local forwarding tunnel"
  printf "%-5s%-22s%s\n" "" "--remote-tunnel=<arg>" "add a remote forwarding tunnel"
  printf "%-5s%-22s%s\n" " -c" "--connect" "connect to a named server"
  printf "%-5s%-22s%s\n" "" "--username=<arg>" "use this username"
  printf "%-5s%-22s%s\n" " -d" "--delete" "delete a named server"
  printf "%-5s%-22s%s\n" "" "--tunnel=<arg>" "delete the tunnel at this index"
  printf "%-5s%-22s%s\n" " -l" "--list" "list saved servers or settings for a named server"
  printf "%-5s%-22s%s\n\n" " -h" "--help" "display help message and exit"
}

add_server()
{
  local server_name=""
  local server_host=""
  local server_user=""
  local server_port=""

  printf "\nServer name: "
  read server_name

  local server_config_file="${config_path}/servers/${server_name}.config"
  if [ -f ${server_config_file} ]; then
    echo "A server with that name already exists"
    exit 1
  fi

  printf "Host: "
  read server_host
  printf "User: "
  read server_user
  printf "Port: "
  read server_port

  echo "host: ${server_host}" > ${server_config_file}
  echo "user: ${server_user}" >> ${server_config_file}
  echo "port: ${server_port}" >> ${server_config_file}
}

add_tunnel_to_server()
{
  local server_name=$1
  local tunnel_type=$2
  local tunnel_string=$3

  local server_config_file="${config_path}/servers/${server_name}.config"
  if ! [ -f ${server_config_file} ]; then
    echo "Error: no server found with name $server_name"
    exit 1
  fi

  case $tunnel_type in
    --local-tunnel )
      echo "local_tunnel: ${tunnel_string}" >> ${server_config_file}
      ;;
    --remote-tunnel )
      echo "remote_tunnel: ${tunnel_string}" >> ${server_config_file}
      ;;
    * )
      echo "Error: Unsupported tunnel type"
      exit 1
      ;;
  esac
}

connect_to_server()
{
  local server_name=$1
  local server_host=""
  local server_user=""
  local server_port="22"
  declare -a local_tunnels
  declare -a remote_tunnels

  if [ "$server_name" = "" ]; then
    echo "Error: Server name cannot be empty"
    exit 1
  fi

  local server_config_file="${config_path}/servers/${server_name}.config"
  while IFS= read cur_line
  do
    if [[ "$cur_line" =~ $argument_regex ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      case $key in
        "host" )
          server_host="$value"
          ;;
        "user" )
          server_user="$value"
          ;;
        "port" )
          server_port="$value"
          ;;
        "local_tunnel" )
          local_tunnels+=($value)
          ;;
      esac
    fi
  done < ${server_config_file}

  if [ "$server_user" = "" ]; then
    echo "Error: The user name cannot be empty. Check server settings"
    exit 1
  elif [ "$server_host" = "" ]; then
    echo "Error: The host cannot be empty. Check server settings"
    exit 1
  fi

  local args_string="${server_user}@${server_host} -p ${server_port}"

  for tunnel in ${local_tunnels[@]}; do
    args_string="$args_string -L $tunnel"
  done

  for tunnel in ${remote_tunnels[@]}; do
    args_string="$args_string -R $tunnel"
  done

  ssh ${args_string}
}

edit_server()
{
  echo "Not implemented"
}

list_servers()
{
  echo ${servers[@]}
}

load_servers()
{
  unset servers
  for entry in ${config_path}/servers/*.config
  do
    [ -f "$entry" ] || break
    local server_name=${entry#"$config_path/servers/"}
    server_name=${server_name%".config"}
    servers+=($server_name)
  done
}

if ! [ -d "${config_path}" ]; then
  printf "Error: Could not find config folder '$config_path'\n"
  exit 1
fi

if ! [ -d "${config_path}/servers" ]; then
  mkdir "${config_path}/servers"
fi

args=("$@")
arg_count=${#args[@]}

if [ $arg_count -eq 0 ]; then
  print_help
  exit 0
fi

load_servers

for (( i=0; i<$arg_count; i++ )); do
  case ${args[$i]} in
    -a | --add )
      if ! [ $i -lt $arg_count ]; then
        add_server
      elif (( i + 3 < arg_count )); then
        add_tunnel_to_server ${args[(($i + 1))]} ${args[(($i + 2))]} ${args[(($i + 3))]}
      else
        printf "Error: Incorrect arguments\n\nUsage: ewac -a <server name> [--local-tunnel=<arg>|--remote-tunnel=<arg>]\n"
        exit 1
      fi
      exit 0
      ;;
    -c | --connect )
      i=$((i + 1))
      if ! [ $i -lt $arg_count ]; then
        printf "Error: Missing server name"
      fi
      connect_to_server ${args[$i]}
      exit 0
      ;;
    -e | --edit )
      ;;
    -l | --list )
      list_servers
      exit 0
      ;;
    -h | --help )
      print_help
      exit 0
      ;;
    * )
      print_help
      exit 1
  esac
  shift
done

# Connect to the task server
# ssh ${user}@ec2-34-253-232-79.eu-west-1.compute.amazonaws.com -p ${port}

