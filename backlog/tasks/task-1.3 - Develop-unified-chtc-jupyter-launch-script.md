---
id: task-1.3
title: Develop unified chtc-jupyter launch script
status: Done
assignee: []
created_date: '2025-11-07 02:23'
completed_date: '2025-11-07 13:45'
labels:
  - jupyter
  - automation
  - phase-2
  - cli
dependencies: []
parent_task_id: task-1
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a single command-line tool that automates the entire Jupyter launch workflow: job submission, SSH tunneling, connection to EP, and browser launch with token URL.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Single chtc-jupyter command handles end-to-end workflow
- [x] #2 Dynamic port allocation prevents user conflicts
- [x] #3 Automatic detection of job start and connection
- [ ] #4 Browser automatically opens with Jupyter token URL (manual copy-paste for now)
- [x] #5 Error handling and user feedback throughout process
- [x] #6 Resume mode for reconnection to existing jobs
<!-- AC:END -->

## Implementation Notes

### Overview
Implemented `chtc-jupyter` script with two modes:
1. **Launch mode**: `./chtc-jupyter` - Full workflow from job submission to active connection
2. **Resume mode**: `./chtc-jupyter resume <JobID> <Port>` - Reconnect to existing job

### Key Technical Challenges & Solutions

#### 1. **macOS grep compatibility**
**Problem**: `grep -P` (Perl regex) not available on macOS  
**Solution**: Changed to portable grep: `grep -o 'submitted to cluster [0-9]*' | grep -o '[0-9]*'`

#### 2. **Bash color codes in command substitution**
**Problem**: Log functions with color codes caused "command not found" errors when captured in `$(...)`  
**Solution**: Redirect all log output to stderr with `>&2`

#### 3. **ProxyJump SSH authentication**
**Problem**: `-o BatchMode=yes` prevented interactive authentication through jump hosts  
**Solution**: Removed BatchMode flag, kept ConnectTimeout only

#### 4. **Port forwarding chain architecture**
**Problem**: Need three-hop forwarding: Laptop → AP → EP  
**Solution**: Create custom SSH wrapper script that adds `-L port:localhost:port` flag:
```bash
temp_ssh=$(mktemp)
cat > "$temp_ssh" << 'EOF'
#!/bin/bash
exec ssh -L ${port}:localhost:${port} "$@"
EOF
condor_ssh_to_job -ssh "$temp_ssh" ${job_id} ...
```

#### 5. **Heredoc "read returned, exiting" issue**
**Problem**: Sending heredocs to `condor_ssh_to_job` caused premature exit, no output  
**Attempted fixes**:
- Using `bash -s` instead of `bash <<<`
- Piping to stdin
- Command strings with `-c`
**Working solution**: Use heredoc but background the entire SSH command from laptop→AP level, not inside the heredoc

#### 6. **Script exiting before port forwarding keepalive**
**Problem**: After showing jupyter.log, script would exit before reaching `tail -f /dev/null`  
**Root cause**: Running everything in one SSH session; condor_ssh_to_job somehow terminated parent SSH  
**Solution**: Split into separate SSH commands:
  1. Display jupyter.log (separate SSH, exits cleanly)
  2. Establish persistent forwarding (dedicated SSH with keepalive)

#### 7. **Jupyter not found in container**
**Problem**: When using command strings instead of heredocs, jupyter command not found  
**Root cause**: Command was being evaluated on AP before being sent to EP  
**Solution**: Stick with heredoc approach (works inside container environment)

#### 8. **Duplicate port forwarding conflicts**
**Problem**: "Address already in use" errors  
**Root cause**: Using custom SSH wrapper for ALL condor_ssh_to_job calls, including log display  
**Solution**: Only use `-ssh "$temp_ssh"` wrapper for:
  - Initial Jupyter launch (establishes EP→AP forwarding)
  - Persistent connection (maintains EP→AP forwarding)
  - NOT for simple commands like `cat jupyter.log`

### Final Architecture

#### Helper Functions
1. **`launch_jupyter()`** - Launches Jupyter on EP via backgrounded SSH→AP→EP chain with heredoc
2. **`show_connection_info()`** - Displays jupyter.log with token and usage instructions
3. **`maintain_port_forwarding()`** - Establishes persistent Laptop→AP→EP forwarding chain with keepalive

#### Launch Mode Flow
```
1. Find common available port on laptop and AP
2. Submit job to HTCondor
3. Wait for job to start (poll JobStatus)
4. Launch Jupyter via backgrounded SSH (launch_jupyter)
5. Wait 20 seconds for startup
6. Display connection info (show_connection_info)
7. Establish persistent forwarding (maintain_port_forwarding)
```

#### Resume Mode Flow
```
1. Display connection info (show_connection_info)
2. Establish persistent forwarding (maintain_port_forwarding)
```

### Critical Implementation Details

**Port forwarding chain** (Laptop → AP → EP):
```bash
# From laptop
ssh -L ${port}:localhost:${port} "${ap_host}" bash << EOFAP
  # On AP - create SSH wrapper
  temp_ssh=$(mktemp)
  cat > "$temp_ssh" << 'EOFSSH'
    #!/bin/bash
    exec ssh -L ${port}:localhost:${port} "$@"
  EOFSSH
  
  # Connect to EP with wrapper
  condor_ssh_to_job -ssh "$temp_ssh" ${job_id} 'tail -f /dev/null'
EOFAP
```

**Backgrounded Jupyter launch**:
```bash
ssh "${ap_host}" bash << EOFAP &  # Background entire SSH command
  condor_ssh_to_job -ssh "$temp_ssh" ${job_id} << 'EOFEP'
    nohup ./launch_jupyter.sh ${port} > jupyter.log 2>&1 &
    exit
  EOFEP
EOFAP
```

### Environment Variables
- `AP_HOST` - Access point hostname (default: ap2002.chtc.wisc.edu)
- `AP_USER` - Username on AP (default: $USER)
- `SUBMIT_FILE` - Submit file path (default: jupyter.sub)
- `LAUNCH_SCRIPT` - Launch script path (default: launch_jupyter.sh)
- `SUBMIT_DIR` - Remote directory (default: /home/$AP_USER/chtc-jupyter)
- `PORT_START/PORT_END` - Port range (default: 8889-8999)

### Files Modified/Created
- `chtc-jupyter` - Main launcher script
- `README-chtc-jupyter.md` - Usage documentation
- `jupyter.def` - Apptainer container definition
- `launch_jupyter.sh` - Jupyter startup script (transferred to EP)
- `jupyter.sub` - HTCondor submit file

### Known Limitations
- No automatic browser opening (user must copy-paste URL)
- Fixed 20-second wait for Jupyter startup
- No health checking of Jupyter process
- Temp SSH scripts created on AP during operation
