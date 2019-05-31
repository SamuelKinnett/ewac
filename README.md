# ewac
EWAC is a simple command line utility for managing SSH connections. I found myself having to multiple different ec2 instances at work during the day and wanted to write something to make the process of remembering and connecting to them a little easier.  
I'm not claiming that this is a superior alternative to other SSH management programs, nor that it's even a good tool full stop, but maybe this will save you some time too!  

## Features
- Save SSH connection details with named profiles
- Store tunnels for connections

## TODO
- Specify custom config directory
- Tunnel deletion
- Certificate file option

## Installation
EWAC creates a config folder under ~/.config/ewac into which it stores server config files.

## Examples
#### Add a server
`ewac -a server_name`
#### Add a local tunnel to an existing server
`ewac -a server_name --local-tunnel 3306:localhost:13306`
#### Connect to a server
`ewac -a server_name`
#### Delete a server
`ewac -d server_name`
#### List servers
`ewac -l`
#### Show server details
`ewac -l server_name`
