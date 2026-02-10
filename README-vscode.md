# CHTC VS Code Remote Launcher

Single script to launch a VS Code Remote session on CHTC HTCondor via **VS Code Tunnels** — run from your laptop.

## How It Works

Unlike the Jupyter launcher (which uses SSH port forwarding), this uses [VS Code Tunnels](https://code.visualstudio.com/docs/remote/tunnels). The execution point initiates an outbound HTTPS connection to Microsoft's relay service, so no port forwarding is needed.

```
Laptop (VS Code) <--Microsoft relay (internet)--> EP (code tunnel)
Laptop (terminal) --SSH--> AP (job management only)
```

The script automates:
1. **Submits job** — Runs `condor_submit vscode.sub` on the AP via SSH
2. **Waits for job** — Monitors job status until it starts running
3. **Launches tunnel** — Starts `code tunnel` on the execution point
4. **GitHub auth** — Displays a one-time device code for GitHub authentication
5. **Connection info** — Tells you how to connect from VS Code Desktop

## Prerequisites

**On your laptop:**
- VS Code with the [Remote - Tunnels](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-server) extension installed
- SSH access to CHTC AP (keys recommended)
- This repo's files: `chtc-vscode`, `vscode.sub`, `launch_vscode.sh`

**On the AP:**
- Container at `/staging/<username>/vscode.sif`

**GitHub account:**
- Required for tunnel authentication (one-time setup per session)

## One-Time Setup

1. **Build the container** on CHTC:
   ```bash
   # Copy build files to the AP
   scp build-vscode.sub vscode.def requirements.txt username@ap2002.chtc.wisc.edu:~/

   # SSH to the AP and submit the build
   ssh username@ap2002.chtc.wisc.edu
   condor_submit -i build-vscode.sub
   
   # When you reach the job running on the AP
   apptainer build vscode.sif vscode.def
   cp vscode.sif /staging/<username>/
   ```

2. **Install the VS Code extension** on your laptop:
    - Open VS Code
    - Install "Remote - Tunnels" extension (`ms-vscode.remote-server`)

3. **Make the launcher executable:**
   ```bash
   chmod +x chtc-vscode
   ```

## Usage

### Start a New Session

```bash
./chtc-vscode
```

The script will guide you through the process. When you see the GitHub device auth prompt:

1. Open https://github.com/login/device in your browser
2. Enter the code shown (e.g., `ABCD-1234`)
3. Authorize "Visual Studio Code"

Once the tunnel is established, connect from VS Code:

1. `Cmd+Shift+P` (or `Ctrl+Shift+P` on Linux)
2. Type "Remote-Tunnels: Connect to Tunnel"
3. Select the tunnel (e.g., `chtc-12345`)

### Resume an Existing Session

If you disconnected your terminal but the job is still running:

```bash
./chtc-vscode resume <JobID>
```

### Stop the Session

The job keeps running after you close your terminal or VS Code. To stop it:

```bash
ssh username@ap2002.chtc.wisc.edu condor_rm <JobID>
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AP_HOST` | `ap2002.chtc.wisc.edu` | Access point hostname |
| `AP_USER` | `$USER` | Username on AP |
| `SUBMIT_FILE` | `vscode.sub` | Local submit file to copy |
| `LAUNCH_SCRIPT` | `launch_vscode.sh` | Local launch script to copy |
| `SUBMIT_DIR` | `/home/$AP_USER/chtc-vscode` | Remote directory on AP |

### Examples

```bash
# Different access point
AP_HOST=ap2001.chtc.wisc.edu ./chtc-vscode

# Different username
AP_USER=myusername ./chtc-vscode
```

## Customizing Resources

Edit `vscode.sub` to change resource requests:

```
# More CPUs and memory
request_cpus = 4
request_memory = 32GB

# Enable GPU
+WantGPULab = true
+GPUJobLength = "short"
request_gpus = 1
```

## Files

| File | Where it runs | Purpose |
|------|--------------|---------|
| `chtc-vscode` | Your laptop | Main launcher script |
| `vscode.sub` | AP | HTCondor submit file |
| `launch_vscode.sh` | EP (in container) | Starts the VS Code tunnel |
| `vscode.def` | Build job | Apptainer container definition |
| `build-vscode.sub` | AP | Submit file for building the container |

## Troubleshooting

### "Could not find the 'code' command"
The VS Code CLI isn't in the container. Rebuild with `build-vscode.sub`.

### GitHub auth prompt doesn't appear
Check the log manually:
```bash
ssh username@ap2002.chtc.wisc.edu condor_ssh_to_job <JobID> 'cat vscode.log'
```

### Tunnel connects but VS Code can't find it
Make sure you're signed into the same GitHub account in VS Code Desktop as you used for the device auth.

### Job is held
Check the hold reason:
```bash
ssh username@ap2002.chtc.wisc.edu condor_q -hold <JobID>
```

### Connection drops / WiFi interruption
The tunnel keeps running on the EP. Just reconnect from VS Code — the tunnel name persists. If you need the tunnel name again:
```bash
./chtc-vscode resume <JobID>
```
