---
id: task-1
title: Simplify Jupyter Lab Launch Workflow on HTCondor
status: Draft
assignee: []
created_date: '2025-11-07 02:14'
labels:
  - ux-improvement
  - jupyter
  - htcondor
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Reduce the complexity of launching Jupyter Lab on HTCondor execution points. Current workflow requires 8+ manual steps including custom SSH scripts, port forwarding, and multiple terminal sessions.

Users - especially GPU/ML users - have repeatedly requested a simpler way to run Jupyter Notebooks in their HTCondor jobs. The current prototype works but has too many manual steps and potential failure points.
<!-- SECTION:DESCRIPTION:END -->

## Problem Statement

### Current Workflow Complexity
The existing prototype requires users to:

1. **Setup Phase** (one-time, but complex):
   - Create custom Apptainer container with JupyterLab installed
   - Write and make executable a custom SSH script (`custom_ssh.sh`)
   - Create a JupyterLab launch script (`launch_jupyter.sh`)
   - Configure a specialized HTCondor submit file

2. **Launch Phase** (every session):
   - Ssh to the AP using port forwarding flags from the laptop
   - Submit the job and note the JobID
   - Wait for job to start (monitoring with `condor_q`)
   - Connect to job using `condor_ssh_to_job` with custom SSH script invoked
   - Run the launch script
   - Copy/paste token URL to browser
   - Keep terminal open for entire session

3. **Teardown Phase**:
   - Shutdown Jupyter server properly
   - Exit SSH sessions
   - Manually `condor_rm` the job

### Pain Points

- **Too many manual steps**: Too many steps just to get Jupyter running
- **Error-prone**: Easy to forget steps or make typos
- **Port conflicts**: Multiple users on same AP may conflict on port 8889
- **Session fragility**: Closing terminal or WiFi interruption kills everything
- **Terminal requirement**: Must keep specific terminal open entire session
- **Limited discoverability**: Requires reading long documentation
- **No automation**: Every launch requires full manual process
- **Resource waste**: Jobs continue running after user disconnects unless manually removed

### Technical Issues Noted

- File transfers through Jupyter UI go through Laptop→AP→EP chain (bandwidth bottleneck)
- Port number conflicts when multiple users active
- Network stress on AP with multiple concurrent users
- Need operations team coordination for production deployment

## Requirements

- **Automation**: Automated launch process with minimal user interaction
- **Port management**: Automatic port assignment or detection to avoid conflicts
- **Session persistence**: Persistent sessions even after terminal closure or network interruptions
- **Discoverability**: Easy-to-use interface for launching Jupyter Lab
- **Resource management**: Efficient resource utilization and job termination on user disconnection

## Potential Solutions

### 1. Unified Launch Script/Command
**Approach**: Create a single `chtc-jupyter` command that handles the entire workflow.

**Implementation**:
- Wrapper script that automates: job submission, port forwarding setup, SSH connection, Jupyter launch
- Auto-detect available ports or use dynamic port allocation
- Handle `condor_ssh_to_job` invocation with proper SSH flags transparently
- Parse Jupyter output and automatically open browser with token URL
- Monitor job status and provide user feedback

**Pros**: Drastically reduces user steps, single command execution
**Cons**: Complex script logic, requires careful error handling
**Effort**: Medium

### 2. Persistent Session Management with `tmux`/`screen`
**Approach**: Run Jupyter server inside a terminal multiplexer on the EP for session resilience.

**Implementation**:
- Launch Jupyter inside `tmux`/`screen` session on EP
- Allow users to disconnect/reconnect without killing Jupyter
- Automated cleanup after job time limit or explicit shutdown

**Pros**: Solves session fragility, allows reconnection
**Cons**: Adds another tool dependency, doesn't reduce initial setup
**Effort**: Low

### 3. HTCondor DAGMan Workflow
**Approach**: Use DAGMan to orchestrate multi-step Jupyter launch/teardown.

**Implementation**:
- DAG with pre-scripts for setup, main job for Jupyter, post-scripts for cleanup
- Automated job removal on Jupyter shutdown
- Could trigger notifications when ready

**Pros**: Leverages existing HTCondor features, reliable orchestration
**Cons**: DAGMan learning curve, may not simplify user-facing complexity
**Effort**: Medium

### 4. SSH ProxyJump Configuration
**Approach**: Simplify SSH connection chain using SSH config file settings.

**Implementation**:
- Provide users with SSH config template using ProxyJump
- Automated port forwarding rules
- Reduces manual SSH command complexity

**Pros**: Standard SSH features, no custom tools
**Cons**: User-side configuration required, doesn't address job management
**Effort**: Low

### Recommended Hybrid Approach

The most impactful strategy combines multiple solutions in phases:

#### Phase 1: Quick Wins (Low Effort, High Impact)
**Goal**: Reduce session fragility and simplify SSH setup
- Implement **Persistent Session Management (#2)** with tmux/screen in the container
  - Users can reconnect after network interruptions
  - Minimal code changes, embedded in container runscript
- Provide **SSH ProxyJump templates (#4)** in documentation
  - Standardize SSH configuration for users
  - Reduces manual command complexity

**Outcome**: Users still follow manual workflow but with better resilience and clearer SSH setup.

#### Phase 2: Automation Layer (Medium Effort, High Impact)
**Goal**: Single-command launch experience
- Develop **Unified Launch Script (#1)** as `chtc-jupyter` command
  - Automates job submission, SSH tunneling, connection
  - Dynamic port allocation to avoid conflicts
  - Automatic browser launch with token URL
  - Integrated with Phase 1 tmux sessions for reconnection support
  
**Outcome**: Users run one command and get Jupyter in their browser. Can reconnect if disconnected.

#### Phase 3: Production Hardening (Medium Effort)
**Goal**: Robust multi-user deployment
- Add **DAGMan orchestration (#3)** for lifecycle management
  - Automated cleanup when Jupyter shuts down
  - Pre/post scripts for resource management
  - Better job monitoring and notifications
- Coordinate with operations team on:
  - Port range allocation strategy
  - AP network capacity planning
  - Monitoring and alerting

**Outcome**: Production-ready service with reliable resource management.

#### Why This Approach?
1. **Incremental value**: Each phase delivers immediate user benefits
2. **Risk mitigation**: Simple changes first, complex automation later
3. **User feedback**: Learn from Phase 1 usage before heavy Phase 2 investment
4. **Resource efficient**: Focuses on highest pain points (fragility, manual steps, cleanup)
## Acceptance Criteria

<!-- TODO: Define when this is "done" -->

## References

- Current prototype: `[Draft] Launching Jupyter Lab from HTC EP.md`
- User-facing guide: https://drive.google.com/file/d/1rSU1Y08h9HRHFEfnWOR9KTIxr2Kbi0qe/view?usp=drive_link
- Related Kestrel approach: https://hpc.chem.wisc.edu/software/kestrel-software/jupyter-notebook/#linux-mac
