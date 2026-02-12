---
id: ni-a5kc
status: closed
deps: []
links: []
created: 2026-02-12T14:32:19Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [nix, update, packages]
---

# Find a good way to update manual package definitions as part of the update process

The 6 manual package derivations in home/packages/ (lulu, blockblock, pearcleaner, pareto-security, macwhisper, firefox-devedition-bin) have hardcoded versions and hashes. The nix:update task only updates flake lockfiles and doesn't touch these. Need to find a good approach to check for new versions and update hashes as part of the regular update workflow.
