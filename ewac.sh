#!/bin/bash

config_path="$HOME/.config/ewac"
argument_regex='^([A-Za-z0-9_]+):[[:space:]]*([A-Za-z0-9_.:-]+)$'
declare -a servers

print_help()
{
  printf "\nManages SSH server connections\n\n"
  printf "Usage:\n"
  printf "  ewac -a [[server name] [--local-tunnel=<arg>|--remote-tunnel=<arg>]]\n"
  printf "  ewac -c <server name> [username]\n"
  printf "  ewac -d <server name> [--tunnel=<arg>]\n"
  printf "  ewac -l [server name]\n\n"
  printf "Options:\n"
  printf "%-5s%-22s%s\n" " -a" "--add" "add a new server"
  printf "%-5s%-22s%s\n" "" "--local-tunnel=<arg>" "add a local forwarding tunnel"
  printf "%-5s%-22s%s\n" "" "--remote-tunnel=<arg>" "add a remote forwarding tunnel"
  printf "%-5s%-22s%s\n" " -c" "--connect" "connect to a named server"
  printf "%-5s%-22s%s\n" " -d" "--delete" "delete a named server"
  printf "%-5s%-22s%s\n" "" "--tunnel=<arg>" "delete the tunnel at this index"
  printf "%-5s%-22s%s\n" " -l" "--list" "list saved servers or settings for a named server"
  printf "%-5s%-22s%s\n\n" " -h" "--help" "display help message and exit"
}

exit_with_error()
{
  echo "Error: ${1}"
  if [ $2 -eq 1 ]; then
    echo "Try 'ewac --help' for more information"
  fi
  exit 1
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
    exit_with_error "a server with that name already exists" 0
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
    exit_with_error "no server found with name $server_name" 0
  fi

  case $tunnel_type in
    --local-tunnel )
      echo "local_tunnel: ${tunnel_string}" >> ${server_config_file}
      ;;
    --remote-tunnel )
      echo "remote_tunnel: ${tunnel_string}" >> ${server_config_file}
      ;;
    * )
      exit_with_error "unsupported tunnel type" 1
      ;;
  esac
}

connect_to_server()
{
  local server_name="$1"
  local server_host=""
  local server_user=""
  local server_port="22"
  declare -a local_tunnels
  declare -a remote_tunnels

  if [ "$server_name" = "" ]; then
    exit_with_error "server name cannot be empty" 0
  fi

  local server_config_file="${config_path}/servers/${server_name}.config"
  if ! [ -f ${server_config_file} ]; then
    exit_with_error "no server found with name $server_name" 0
  fi

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
        "remote_tunnel" )
          remote_tunnels+=($value)
          ;;
      esac
    fi
  done < ${server_config_file}

  if [ $# -gt 1 ]; then
    server_user="$2"
  fi

  if [ "$server_user" = "" ]; then
    exit_with_error "the user name cannot be empty. Check server settings" 0
  elif [ "$server_host" = "" ]; then
    exit_with_error "the host cannot be empty. Check server settings" 0
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

delete_server()
{
  server_name="$1"
  local server_config_file="${config_path}/servers/${server_name}.config"
  if ! [ -f ${server_config_file} ]; then
    exit_with_error "no server found with name $server_name" 0
  fi

  printf "Really delete $server_name? (y/n): "
  read choice

  if [ "$choice" == "Y" ] || [ "$choice" == "y"]; then
    rm ${server_config_file}
  else
    echo "$server_name will not be deleted"
  fi
}

delete_server_tunnel()
{
  exit_with_error "not implemented yet" 0

  server_name="$1"
  local server_config_file="${config_path}/servers/${server_name}.config"
  if ! [ -f ${server_config_file} ]; then
    exit_with_error "no server found with name $server_name" 0
  fi
}

list_servers()
{
  for server_name in ${servers[@]}; do
    echo "$server_name"
  done
}

list_server_details()
{
  server_name="$1"
  local server_host=""
  local server_user=""
  local server_port=""
  declare -a local_tunnels
  declare -a remote_tunnels

  local server_config_file="${config_path}/servers/${server_name}.config"
  if ! [ -f ${server_config_file} ]; then
    exit_with_error "no server found with name $server_name" 0
  fi

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
        "remote_tunnel" )
          remote_tunnels+=($value)
          ;;
      esac
    fi
  done < ${server_config_file}

  echo "$server_name"
  echo "Host: $server_host"
  echo "User: $server_user"
  echo "Port: $server_port"
  echo "Local tunnels:"
  for (( c=0; c<${#local_tunnels[@]}; c++ )); do
    printf "%-3s%s\n" "$c" "${local_tunnels[$c]}"
  done
  echo "Remote tunnels:"
  for (( c=0; c<${#remote_tunnels[@]}; c++ )); do
    printf "%-3s%s\n" "$c" "${remote_tunnels[$c]}"
  done
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
  exit_with_error "could not find config folder '$config_path'" 0
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
      if (( i == $arg_count - 1 )); then
        add_server
      elif (( i + 3 < arg_count )); then
        add_tunnel_to_server ${args[(($i + 1))]} ${args[(($i + 2))]} ${args[(($i + 3))]}
      else
        exit_with_error "incorrect arguments" 1
      fi
      exit 0
      ;;
    -c | --connect )
      i=$((i + 1))
      if ! [ $i -lt $arg_count ]; then
        exit_with_error "missing server name" 0
      elif (( i + 1 == arg_count )); then
        connect_to_server ${args[$i]}
      elif (( i + 2 == arg_count)); then
        connect_to_server ${args[$i]} ${args[(($i + 1))]}
      else
        exit_with_error "incorrect arguments" 1
      fi
      exit 0
      ;;
    -d | --delete )
      delete_server
      exit 0
      ;;
    -l | --list )
      if (( i == $arg_count - 1 )); then
        list_servers
      elif (( i + 1 == $arg_count - 1 )); then
        list_server_details ${args[(($i + 1))]}
      else
        exit_with_error "incorrect arguments" 1
      fi
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
