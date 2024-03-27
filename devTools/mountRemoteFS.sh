#!/bin/bash

sudo sshfs -o IdentityFile=/home/noname/.ssh/nopasswd/id_rsa,allow_other,default_permissions noname@192.168.4.150:/data/scripts ./remoteScripts