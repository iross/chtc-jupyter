#!/bin/bash

port_number="$1"
if [[ "${port_number}x" == "x" ]] ; then
    port_number=8889
fi

export HOME=$(pwd)

# Check if jupyter is available
which jupyter > /dev/null 2>&1
exit_code="$?"
if [[ "${exit_code}" != 0 ]] ; then
    cat << EOF

    Error: Could not find the 'jupyter' command!
    Run 'source /opt/conda/bin/activate' and try again.

EOF
exit 1
fi
jupyter lab --no-browser --port=${port_number}
