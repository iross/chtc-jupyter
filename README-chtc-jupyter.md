# CHTC Jupyter Launcher

Single script to automate the Jupyter Lab launch workflow on CHTC HTCondor.

## What It Does

Automates these manual steps:
1. Submit `jupyter.sub`
2. Wait for job to start
3. Connect via `condor_ssh_to_job` with port forwarding
4. Launch Jupyter on the execution point

## Prerequisites

Before running on the **access point**, you need:
- `jupyter.sub` - Your HTCondor submit file
- `launch_jupyter.sh` - Script to launch Jupyter (transferred with job)
- Container in `/staging/` (referenced in submit file)

On your **laptop**, SSH to the AP with port forwarding:
```bash
ssh -L 8889:localhost:8889 username@ap2002.chtc.wisc.edu
```

## Usage

Basic:
```bash
./chtc-jupyter
```

Custom port:
```bash
PORT=8890 ./chtc-jupyter
```

Custom submit file:
```bash
SUBMIT_FILE=my-jupyter.sub ./chtc-jupyter
```

Both:
```bash
PORT=8890 SUBMIT_FILE=my-jupyter.sub ./chtc-jupyter
```

## Complete Workflow

### 1. On your laptop, connect with port forwarding:
```bash
ssh -L 8889:localhost:8889 username@ap2002.chtc.wisc.edu
```

### 2. On the AP, launch Jupyter:
```bash
./chtc-jupyter
```

The script will:
- Submit your job
- Wait for it to start (shows dots while waiting)
- Connect to the execution point
- Start Jupyter Lab
- Display the connection URL

### 3. On your laptop, open the URL in your browser:
```
http://127.0.0.1:8889/lab?token=abc123...
```

### 4. When done:
- Shutdown Jupyter (File → Shut Down) or press Ctrl+C
- The job will keep running until the time limit
- Manually remove it: `condor_rm <JobID>`

## Comparison

**Before:**
```bash
ssh -L 8889:localhost:8889 user@ap  # On laptop
condor_submit jupyter.sub            # On AP
condor_watch_q                        # Wait...
condor_ssh_to_job -ssh ./custom_ssh.sh 12345
source /opt/conda/bin/activate        # On EP
./launch_jupyter.sh 8889
# Copy URL to browser
```

**After:**
```bash
ssh -L 8889:localhost:8889 user@ap  # On laptop
./chtc-jupyter                       # On AP
# Copy URL to browser
```

## Port Management

### Single Session
Default port 8889 works fine:
```bash
./chtc-jupyter
```

### Multiple Sessions
Use different ports for each session:
```bash
# Terminal 1
PORT=8889 ./chtc-jupyter

# Terminal 2 (new SSH session with -L 8890:localhost:8890)
PORT=8890 ./chtc-jupyter
```

Remember to forward all ports when SSH'ing:
```bash
ssh -L 8889:localhost:8889 -L 8890:localhost:8890 user@ap
```

## Troubleshooting

**"Submit file not found"**
```bash
# Make sure jupyter.sub exists
ls -l jupyter.sub

# Or specify location
SUBMIT_FILE=/path/to/jupyter.sub ./chtc-jupyter
```

**"Job is held"**
```bash
# Check why
condor_q -hold

# Common causes:
# - Container path wrong in submit file
# - Requirements too restrictive
```

**"Connection fails" / "Port forwarding error"**
```bash
# Make sure you forwarded the port when SSH'ing to AP
exit
ssh -L 8889:localhost:8889 user@ap2002.chtc.wisc.edu
```

**Job keeps running after I disconnect**
```bash
# Jobs run for full duration (e.g., 12h)
# Remove manually when done
condor_rm <JobID>
```

## SSH Config Tip

Add to `~/.ssh/config` on your laptop:
```ssh
Host chtc
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
    LocalForward 8889 localhost:8889
    LocalForward 8890 localhost:8890
```

Then just:
```bash
ssh chtc
```

## Files

- `chtc-jupyter` - This launcher script (make executable)
- `jupyter.sub` - Your submit file
- `launch_jupyter.sh` - Runs on EP to start Jupyter
- `custom_ssh.sh` - Not needed anymore!
