# CHTC Jupyter Launcher

Single script to automate the Jupyter Lab launch workflow on CHTC HTCondor - **run from your laptop**.

## What It Does

Automates the entire workflow:
1. **Scans ports** - Finds a port available on both your laptop AND the AP
2. **Submits job** - Runs `condor_submit jupyter.sub` on the AP via SSH
3. **Waits for job** - Monitors job status until it starts running
4. **Connects** - Establishes SSH tunnel chain: laptop → AP → EP
5. **Launches Jupyter** - Starts Jupyter Lab on the execution point
6. **Displays URL** - Shows you the token URL to paste in your browser

## Prerequisites

**On your laptop**:
- `jupyter.sub` - Your HTCondor submit file (will be copied to AP)
- SSH access to CHTC AP (keys recommended)
- This `chtc-jupyter` script

**On the AP** (referenced in submit file):
- `launch_jupyter.sh` - Script to launch Jupyter (transferred with job)
- Container in `/staging/` (referenced in submit file)

## Usage

Basic (uses all defaults):
```bash
./chtc-jupyter
```

Custom access point:
```bash
AP_HOST=ap2001.chtc.wisc.edu ./chtc-jupyter
```

Custom username:
```bash
AP_USER=myusername ./chtc-jupyter
```

Custom submit file:
```bash
SUBMIT_FILE=my-jupyter.sub ./chtc-jupyter
```

Custom remote directory on AP:
```bash
SUBMIT_DIR=/home/username/my-jobs ./chtc-jupyter
```

Custom port range:
```bash
PORT_START=9000 PORT_END=9100 ./chtc-jupyter
```

## Complete Workflow Example

### One-Time Setup

1. **On your laptop**, prepare your files:
   ```bash
   # Make sure you have jupyter.sub locally
   ls -l jupyter.sub
   
   # Make the launcher executable
   chmod +x chtc-jupyter
   ```

2. **On the AP**, make sure referenced files exist:
   ```bash
   ssh username@ap2002.chtc.wisc.edu
   ls -l launch_jupyter.sh
   # Make sure your container is in /staging/
   ```

### Every Session

**Just run the script from your laptop:**
```bash
./chtc-jupyter
```

The script will:
1. Test SSH connection to the AP
2. Scan for available ports (shows progress)
3. Copy jupyter.sub to the AP (into ~/chtc-jupyter/ by default)
4. Submit the job
5. Wait for it to start (shows dots)
6. Connect and launch Jupyter
7. Display the URL

**Copy the URL** (looks like `http://127.0.0.1:8889/lab?token=abc123...`) and paste it into your browser.

**That's it!** You're now running Jupyter on an HTCondor execution point.

### When Done

Press **Ctrl+C** in the terminal to disconnect.

**Important**: The job continues running until the time limit. Remove it manually:
```bash
# SSH to the AP
ssh username@ap2002.chtc.wisc.edu

# Remove the job
condor_rm <JobID>
```

## How Port Scanning Works

The script intelligently finds a port that works for everyone:

1. **Scans your laptop** (ports 8889-8999 by default)
   - Finds ports not in use locally
   
2. **Scans the AP** via SSH
   - Checks which of those ports are also free on the AP
   
3. **Uses the first common port**
   - Ensures no conflicts with other users

This means **you don't need to manually specify ports** and **multiple users can run simultaneously** without conflicts!

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AP_HOST` | `ap2002.chtc.wisc.edu` | Access point hostname |
| `AP_USER` | `$USER` | Username on AP |
| `SUBMIT_FILE` | `jupyter.sub` | Local submit file to copy |
| `SUBMIT_DIR` | `$HOME/chtc-jupyter` | Remote directory on AP |
| `PORT_START` | `8889` | Port range start |
| `PORT_END` | `8999` | Port range end |

## Comparison: Before vs After

### Before (Manual)
```bash
# 1. SSH with port forwarding (need to pick port manually)
ssh -L 8889:localhost:8889 username@ap2002.chtc.wisc.edu

# 2. Submit job
condor_submit jupyter.sub

# 3. Wait and check
condor_watch_q

# 4. Get job ID, create custom SSH script
condor_ssh_to_job -ssh ./custom_ssh.sh 12345

# 5. Activate environment
source /opt/conda/bin/activate

# 6. Launch Jupyter
./launch_jupyter.sh 8889

# 7. Copy URL to browser
```

**Steps**: 7-8 manual commands  
**Port conflicts**: Manual resolution  
**Time**: 5-10 minutes

### After (Automated)
```bash
./chtc-jupyter
# Copy URL to browser
```

**Steps**: 1 command  
**Port conflicts**: Automatic resolution  
**Time**: 1-2 minutes (mostly waiting for job to start)

## Multiple Sessions

Want to run multiple Jupyter sessions at once?

```bash
# Terminal 1
./chtc-jupyter
# Uses port 8889

# Terminal 2
./chtc-jupyter
# Automatically uses port 8890 (or next available)
```

No manual port management needed!

## Troubleshooting

### "Cannot connect to AP"
```bash
# Test SSH access
ssh username@ap2002.chtc.wisc.edu

# Set up SSH keys if needed
ssh-copy-id username@ap2002.chtc.wisc.edu

# Or specify username explicitly
AP_USER=myusername ./chtc-jupyter
```

### "Submit file not found locally"
```bash
# Make sure jupyter.sub exists on your laptop
ls -l jupyter.sub

# Or specify a different file
SUBMIT_FILE=~/jupyter-configs/my-jupyter.sub ./chtc-jupyter
```

### "Job is held"
```bash
# The script will tell you to run:
ssh username@ap2002.chtc.wisc.edu condor_q -hold <JobID>

# Common causes:
# - Container not found in /staging/
# - Requirements too restrictive
# - Out of quota
```

### "No available ports"
```bash
# Check what's using ports on your laptop
lsof -Pi :8889-8999

# Kill old processes or use different range
PORT_START=9000 PORT_END=9100 ./chtc-jupyter
```

### "Connection drops / WiFi interruption"

Currently, if your connection drops, Jupyter stops. You'll need to:
1. Rerun `./chtc-jupyter` (submits a new job)
2. Or manually reconnect (future enhancement with tmux - task-1.1)

### "Job keeps running after disconnect"

This is expected behavior. HTCondor jobs run for their full duration.

**To stop it:**
```bash
ssh username@ap2002.chtc.wisc.edu
condor_rm <JobID>
```

**Future enhancement**: Automatic cleanup (task-1.4)

## Advanced Usage

### Different Submit Files for Different Scenarios

Create multiple submit files:
```bash
# CPU-only session
SUBMIT_FILE=jupyter-cpu.sub ./chtc-jupyter

# GPU session
SUBMIT_FILE=jupyter-gpu.sub ./chtc-jupyter

# Large memory
SUBMIT_FILE=jupyter-bigmem.sub ./chtc-jupyter
```

### Scripting / Automation

```bash
#!/bin/bash
# auto-launch-jupyter.sh

# Set variables
export AP_HOST=ap2002.chtc.wisc.edu
export AP_USER=myusername
export SUBMIT_FILE=jupyter.sub

# Launch
./chtc-jupyter
```

## What's Still Manual?

1. **Copying the URL** - You still need to paste it into your browser
   - Future: Could auto-open browser (but URL has token)
   
2. **Job cleanup** - You need to `condor_rm` when done
   - Future: Automatic cleanup on disconnect (task-1.4)
   
3. **Reconnection** - If connection drops, Jupyter stops
   - Future: tmux/screen integration (task-1.1)

## Files

**On your laptop:**
- `chtc-jupyter` - This launcher script
- `jupyter.sub` - Your submit file (copied to AP automatically)

**On the AP:**
- `launch_jupyter.sh` - EP launcher (transferred with job via submit file)
- Container in `/staging/` (referenced in submit file)
- `~/chtc-jupyter/` - Created automatically by script (contains copied submit file)

**No longer needed:**
- ❌ `custom_ssh.sh` - Script handles this internally
- ❌ Manual SSH port forwarding - Script does it automatically

## Future Enhancements

See backlog for planned improvements:
- **task-1.1**: tmux/screen for session persistence
- **task-1.2**: SSH config templates (optional optimization)
- **task-1.4**: Automatic job cleanup on disconnect
