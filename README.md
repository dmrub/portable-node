portable-node
=============

Install node.js locally on Windows and Linux without administrator rights.

Instructions
------------

Download and run https://raw.github.com/dmrub/portable-node/master/bin/install-node.vbs.
The script will download recent version of node.js and create startup files for node.js and git bash.

For more options run from command line (cmd.exe or git bash):

    > cscript install-node.vbs /?

    Node Portable Environment Setup Script
    Usage : install-node.vbs [ /? ] [/version:node-version /arch:x86|x86_64|32|64 /force]

    Options: /version:node-version         select node version to download (default : 0.10.0)
        /arch:x86|x64|x86_64|32|64    select node architecture to download (default : x86)
        /force                        force download and installation
        /?                            print this

Enjoy !


