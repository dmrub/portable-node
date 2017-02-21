portable-node
=============

Install node.js locally on Windows and Linux without administrator rights.

Note: when specifying version at the command line, a full version number (MAJOR.MINOR.PATCH) must be specified !

Windows Instructions
--------------------

Download and run https://raw.github.com/dmrub/portable-node/master/bin/install-node.vbs.
The script will download recent version of node.js and create startup files for node.js and git bash.

For more options run from command line (cmd.exe or git bash):

    > cscript install-node.vbs /?

    Node Portable Environment Setup Script
    Usage : install-node.vbs [ /? ] [/version:node-version /arch:x86|x86_64|32|64 /force]

    Options: /version:node-version         select node version to download (default : 6.9.5)
        /arch:x86|x64|x86_64|32|64    select node architecture to download (default : x86)
        /force                        force download and installation
        /?                            print this

Linux Instructions
--------------------

Download and run https://raw.github.com/dmrub/portable-node/master/bin/install-node.sh.

For example:

    wget https://raw.github.com/dmrub/portable-node/master/bin/install-node.sh
    chmod +x ./install-node.sh
    ./install-node.sh

For more options run from command line:

    > ./install-node.sh --help
    Node Portable Environment Setup Script
    Usage: ./install-node.sh [options]
    options :
        -h | --help                   print this
        -v | --version=node-version   select node version to download (default : 6.9.5)
        -a | --arch=x86|x86_64|32|64  select node architecture to download (default : x64)
        -f | --force                  force download and installation

Enjoy !
