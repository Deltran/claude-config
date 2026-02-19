---
description: Before running system-level commands (asdf, npm, MySQL, etc.), check --version and --help first. Never assume the environment matches your expectations.
---
# Verify Tool Versions Before Building Features

Two separate incidents cemented this rule. First: the user works across multiple machines and shares memory between them — tool versions differ between environments, so assuming the environment is consistent is wrong by default. Second, and more costly: an entire PHP feature was developed and shipped against a PHP version that wasn't going to be used in production. The whole codebase had to be downgraded after the fact. Days of rework from an assumption that took seconds to verify.

The practice: before running any system-level command — asdf, npm global installs, MySQL operations, anything environment-dependent — check `--version` and `--help` first. Verify the tool, verify the syntax, verify privilege level if needed (`whoami`). Never assume.

The cost asymmetry is the reason this is a hard rule. Checking takes seconds. Building for the wrong target can cost days. Any time saved by skipping the check is immediately dwarfed by the first time the assumption turns out to be wrong.
