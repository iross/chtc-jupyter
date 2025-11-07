#!/bin/bash
# custom_ssh.sh

exec ssh -L 8890:localhost:8890 "$@" 

