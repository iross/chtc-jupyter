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
- `launch_jupyter.sh` - Script to launch Jupyter (will be copied to AP)
- SSH access to CHTC AP (keys recommended)
- This `chtc-jupyter` script

**On the AP** (referenced in submit file):
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
   # Make sure you have the required files locally
   ls -l jupyter.sub launch_jupyter.sh

   # Make the launcher executable
   chmod +x chtc-jupyter
   ```

2. **On the AP**, make sure your container exists:
   ```bash
   ssh username@ap2002.chtc.wisc.edu
   # Make sure your container is in /staging/
   ls -l /staging/$(whoami)/jupyter.sif
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

## Troubleshooting

### "Submit file not found locally"
```bash
# Make sure jupyter.sub exists on your laptop
ls -l jupyter.sub

# Or specify a different file
SUBMIT_FILE=~/jupyter-configs/my-jupyter.sub ./chtc-jupyter
```

### "Connection drops / WiFi interruption"

Currently, if your connection drops, Jupyter stops. You'll need to:
1. Run `./chtc-jupyter resume <JobID> <Port>`, as specified in the output

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
## Files

**On your laptop:**
- `chtc-jupyter` - This launcher script
- `jupyter.sub` - Your submit file (copied to AP automatically)

**On the AP:**
- `launch_jupyter.sh` - EP launcher (transferred with job via submit file)
- Container in `/staging/` (referenced in submit file)
- `~/chtc-jupyter/` - Created automatically by script (contains copied submit file)

## Optional: SSH Configuration

For users who frequently connect to CHTC access points, you can optionally set up SSH configuration shortcuts to:
- Use short aliases instead of full hostnames (`ssh chtc-ap`)
- Enable connection reuse (no re-authentication for 10 minutes)
- Automatically keep connections alive during long sessions

**This is completely optional** - the `chtc-jupyter` script works perfectly without any SSH config customization.

**Files:**
- **`ssh-config-template`** - Copy-paste SSH config examples
- **`ssh-config-guide.md`** - Comprehensive guide with security considerations

**Security note**: Some configurations (like ControlMaster) should only be used on personal, secure workstations. Read the guide before using.
