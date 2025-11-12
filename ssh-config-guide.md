# SSH Configuration Guide for CHTC Jupyter Sessions

**Optional optimization for advanced users**

This guide explains how to use SSH configuration files to streamline your connection workflow when using CHTC Jupyter sessions. **This is entirely optional** - the `chtc-jupyter` script works perfectly without any SSH config customization.

## Table of Contents
- [What is SSH Config?](#what-is-ssh-config)
- [Why Use SSH Config?](#why-use-ssh-config)
- [Should You Use This?](#should-you-use-this)
- [Quick Start](#quick-start)
- [Configuration Options](#configuration-options)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## What is SSH Config?

SSH configuration files (`~/.ssh/config`) allow you to define connection settings, aliases, and defaults for SSH connections. Instead of typing full commands with all options every time, you can define them once in the config file and use short aliases.

**Example - Without SSH config:**
```bash
ssh username@ap2002.chtc.wisc.edu
```

**Example - With SSH config:**
```bash
ssh chtc-ap
```

The SSH config file is a standard OpenSSH feature available on macOS, Linux, and Windows (via WSL or modern Windows OpenSSH).

For complete documentation: `man ssh_config` or https://www.openssh.com/manual.html

## Why Use SSH Config?

### Benefits

1. **Shorter commands**: Use aliases instead of full hostnames
2. **Consistent settings**: Define connection parameters once
3. **Connection reuse**: ControlMaster eliminates re-authentication

### What You Get With CHTC

- **Alias**: Type `ssh chtc-ap` instead of `ssh username@ap2002.chtc.wisc.edu`
- **Fast reconnect**: ControlMaster reuses connections (no re-entering password)

## Should You Use This?

### ✅ Good reasons to use SSH config:

- You frequently connect to CHTC access points from your personal laptop
- You want faster subsequent connections (ControlMaster)
- You work with multiple access points and want consistent settings
- You prefer shorter, memorable commands

### ⚠️ Consider skipping if:

- You're happy with the current workflow (it works great as-is!)
- You work on shared or lab computers (security concerns)
- You're not comfortable with command-line configuration
- You rarely use CHTC (one-time setup overhead not worth it)
- Your organization has specific SSH policies

**Bottom line**: This is a convenience optimization, not a requirement. The `chtc-jupyter` script is designed to work perfectly without any SSH config customization.

## Quick Start

### 1. Check if you have an SSH config

```bash
ls -la ~/.ssh/config
```

If it doesn't exist, that's fine - we'll create it.

### 2. Backup existing config (if you have one)

```bash
cp ~/.ssh/config ~/.ssh/config.backup
```

### 3. Choose your configuration level

We provide several configuration levels. Start simple and add more if needed:

#### Level 1: Basic Alias (Recommended for beginners)
```bash
# Add to ~/.ssh/config
Host chtc-ap
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
```

**What this gives you:**
- Short alias: `ssh chtc-ap`

#### Level 2: Connection Reuse with ControlMaster (Recommended)
```bash
# Add to ~/.ssh/config
Host chtc-ap-shared
    HostName ap2002.chtc.wisc.edu
    User YOUR_USERNAME
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
```

**What this adds:**
- First connection requires authentication
- Subsequent connections in next 10 minutes are instant (no re-auth)
- Perfect for running `chtc-jupyter` multiple times

**Security note**: See [Security Considerations](#security-considerations) below

### 4. Edit the file

```bash
# On macOS/Linux
nano ~/.ssh/config

# Or use your preferred editor
vim ~/.ssh/config
code ~/.ssh/config
```

Paste your chosen configuration and **replace `YOUR_USERNAME`** with your actual CHTC username.

### 5. Set correct permissions

```bash
chmod 600 ~/.ssh/config
```

This is required for security. SSH will refuse to use the config if permissions are too open.

### 6. Test it

```bash
# Try your new alias
ssh chtc-ap

# If it works, you're done!
```

## Configuration Options

### Essential Settings

#### `HostName`
The actual server address. Required.
```
HostName ap2002.chtc.wisc.edu
```

#### `User`
Your username on the remote system. Saves typing.
```
User YOUR_USERNAME
```

### Connection Reuse (ControlMaster)

ControlMaster allows multiple SSH sessions to share a single connection.

```
ControlMaster auto                          # Enable automatic connection re-use
ControlPath ~/.ssh/control-%r@%h:%p        # Where to store the socket
ControlPersist 10m                          # Keep connection for 10 minutes after last session
```

**How it works:**
1. First SSH connection authenticates normally (password/2FA)
2. SSH creates a control socket file in `~/.ssh/`
3. Subsequent connections reuse the existing authenticated connection
4. No need to re-enter password or use 2FA again
5. After 10 minutes of no activity, the master connection closes

**Benefits:**
- Much faster subsequent connections (instant)
- Single authentication for multiple windows/sessions
- Useful when running `chtc-jupyter` repeatedly during development

**Security implications:**
- Anyone who can access your user account can reuse the connection
- On shared computers, other users might piggyback on your session
- Socket files may be accessible depending on `/tmp` permissions
- **Only use on your personal, secure workstation**

**Documentation**: `man ssh_config` (search for ControlMaster)
**More info**: https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing

## Security Considerations

### ControlMaster Security

**The Risk:**
- ControlMaster creates a Unix socket file that allows connection reuse
- Anyone who can access this socket can use your authenticated connection
- On multi-user systems, this could allow privilege escalation


## Examples

### Minimal Setup (Recommended for most users)

```bash
# ~/.ssh/config
Host chtc-ap
    HostName ap2002.chtc.wisc.edu
    User myusername
```

**Usage:**
```bash
# Connect to AP
ssh chtc-ap

# Use with chtc-jupyter (works automatically)
./chtc-jupyter
```

### With ControlMaster (Personal laptop only)

```bash
# ~/.ssh/config
Host chtc-ap
    HostName ap2002.chtc.wisc.edu
    User myusername
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
```

**Usage:**
```bash
# First connection - authenticates normally
ssh chtc-ap

# Subsequent connections within 10 minutes - instant!
ssh chtc-ap
./chtc-jupyter
```
