#!/bin/bash

tunnel_name="${1:-chtc-$(hostname | cut -d. -f1)}"

export HOME=$(pwd)

# Check if code CLI is available
which code > /dev/null 2>&1
exit_code="$?"
if [[ "${exit_code}" != 0 ]] ; then
    cat << EOF

    Error: Could not find the 'code' command!
    The VS Code CLI may not be installed in this container.

EOF
exit 1
fi

code tunnel --accept-server-license-terms --name "$tunnel_name"
