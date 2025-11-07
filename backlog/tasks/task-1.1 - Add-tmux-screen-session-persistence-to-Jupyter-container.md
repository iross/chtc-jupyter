---
id: task-1.1
title: Add tmux/screen session persistence to Jupyter container
status: To Do
assignee: []
created_date: '2025-11-07 02:23'
labels:
  - jupyter
  - container
  - phase-1
dependencies: []
parent_task_id: task-1
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Embed tmux/screen in the Apptainer container runscript to enable session persistence. Users should be able to reconnect after network interruptions without losing their Jupyter session.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Jupyter runs inside tmux/screen session on EP
- [ ] #2 Users can disconnect and reconnect without killing Jupyter
- [ ] #3 Container runscript handles tmux session creation/attachment
- [ ] #4 Documentation includes reconnection instructions
<!-- AC:END -->
