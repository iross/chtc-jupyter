# SSH Configuration Template for CHTC Jupyter Sessions

**Task**: task-1.2 - Create SSH ProxyJump configuration template  
**Status**: Draft Solution  
**Date**: 2025-11-07

## Overview

This document outlines an SSH configuration approach to simplify the Jupyter Lab connection workflow on CHTC HTCondor systems. Instead of users manually typing complex SSH commands with port forwarding flags, they can use a standardized SSH config file.

## Problem Being Solved

Currently, users must:
1. SSH to the AP with port forwarding: `ssh -L 8889:localhost:8889 username@ap2002.chtc.wisc.edu`
2. Use `condor_ssh_to_job` with a custom SSH script that also does port forwarding
3. Remember port numbers and keep them consistent across multiple steps

This is error-prone and requires keeping track of multiple commands and port numbers.

## Proposed Solution

### SSH Config Template

Create a template SSH config file that users can add to their `~/.ssh/config`:

```ssh
# CHTC Jupyter Lab Configuration
# Add this to your ~/.ssh/config file

# Define the CHTC Access Point
Host chtc-ap
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
    # Port forwarding for Jupyter Lab
    LocalForward 8889 localhost:8889
    # Keep connection alive
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Alternative access points (uncomment as needed)
# Host chtc-ap2001
#     HostName ap2001.chtc.wisc.edu
#     User YOUR_USERNAME
#     LocalForward 8889 localhost:8889
#     ServerAliveInterval 60
#     ServerAliveCountMax 3

# ProxyJump configuration for execution points
# This allows direct SSH to EP through the AP
Host chtc-ep-*
    User YOUR_USERNAME
    ProxyJump chtc-ap
    # Forward the same port through the proxy
    LocalForward 8889 localhost:8889
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### Custom SSH Script Template

Update the `custom_ssh.sh` script to be simpler:

```bash
#!/bin/bash
# custom_ssh.sh - Simplified version using SSH config

# Just pass through to SSH with port forwarding
# The SSH config handles the rest
exec ssh -L 8889:localhost:8889 "$@"
```

Or even better, if using the SSH config properly, this script may not be needed at all.

### Multi-Port Support

For users who want to run multiple Jupyter sessions or avoid conflicts:

```ssh
# CHTC Jupyter Lab - Configurable Port Version
Host chtc-jupyter-*
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
    # Use different ports: chtc-jupyter-8889, chtc-jupyter-8890, etc.
    LocalForward %h 8889:localhost:8889
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Usage Instructions

### Setup (One-time)

1. **Edit your SSH config**:
   ```bash
   nano ~/.ssh/config
   ```

2. **Add the template** (copy the SSH Config Template above)

3. **Replace `YOUR_USERNAME`** with your CHTC username

4. **Set permissions**:
   ```bash
   chmod 600 ~/.ssh/config
   ```

### Connecting to Jupyter

#### Option 1: Using the SSH config alias
```bash
# Connect to AP (port forwarding automatic)
ssh chtc-ap

# Submit job
condor_submit jupyter.sub

# Wait for job to start
condor_watch_q

# Connect to job (simplified)
condor_ssh_to_job -ssh /path/to/custom_ssh.sh <JobID>
```

#### Option 2: Even simpler with environment variable
Set up a helper function in your `.bashrc` or `.zshrc`:

```bash
# Add to ~/.bashrc or ~/.zshrc
chtc-jupyter-connect() {
    if [ -z "$1" ]; then
        echo "Usage: chtc-jupyter-connect <JobID>"
        return 1
    fi
    
    local jobid=$1
    local custom_ssh_script="$HOME/.chtc/custom_ssh.sh"
    
    echo "Connecting to Jupyter job $jobid..."
    condor_ssh_to_job -ssh "$custom_ssh_script" "$jobid"
}
```

Then usage becomes:
```bash
ssh chtc-ap
condor_submit jupyter.sub
# ... wait for job ...
chtc-jupyter-connect <JobID>
```

## Advanced: Dynamic Port Assignment

For environments with multiple users, support dynamic ports:

```bash
#!/bin/bash
# smart_ssh_jupyter.sh - Finds available port automatically

find_available_port() {
    local port
    for port in {8889..8999}; do
        if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo $port
            return 0
        fi
    done
    echo "No available ports in range 8889-8999" >&2
    return 1
}

PORT=$(find_available_port)
if [ $? -eq 0 ]; then
    echo "Using port $PORT for Jupyter session"
    exec ssh -L $PORT:localhost:$PORT "$@"
else
    exit 1
fi
```

Update SSH config to reference this:
```ssh
Host chtc-ap
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
    # Dynamic port forwarding handled by wrapper script
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Benefits

1. **Reduced typing**: No need to remember port forwarding flags
2. **Consistency**: Port numbers defined in one place
3. **Connection stability**: ServerAlive settings prevent timeouts
4. **Flexibility**: Easy to switch between access points
5. **Discoverable**: Config file documents the setup for future reference

## Limitations

- Still requires users to edit their local SSH config (one-time setup)
- Doesn't solve the multi-step launch process
- Port conflicts still possible with hardcoded ports (mitigated by dynamic version)

## Documentation Deliverables

1. **User guide** explaining:
   - What SSH config is and where to find it
   - Step-by-step setup instructions
   - Troubleshooting common issues
   - How to verify it's working

2. **Template file** that users can copy directly:
   - Hosted in repo as `ssh-config-template`
   - Includes comments explaining each section
   - Multiple examples for different use cases

3. **Quick reference card**:
   - One-page cheat sheet
   - Before/after command comparison
   - Common customizations

## Testing Plan

1. Test on fresh user account (no existing SSH config)
2. Test with existing SSH config (no conflicts)
3. Test with multiple simultaneous sessions
4. Test on different platforms (macOS, Linux, Windows WSL)
5. Verify port forwarding works through ProxyJump
6. Test connection recovery after network interruption

## Future Enhancements

- Integration with the unified launch script (task-1.3)
- Automatic SSH config generation tool
- CHTC-specific SSH config installer script
- Support for SSH multiplexing (ControlMaster) for faster reconnections

## References

- OpenSSH ProxyJump documentation: https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts
- SSH Config file format: `man ssh_config`
- Current prototype: `[Draft] Launching Jupyter Lab from HTC EP.md`
