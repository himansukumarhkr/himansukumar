# GitLab Batch Committer

A lightweight, portable Git automation tool designed for Windows and corporate VDI environments. It commits code from a local source text file into a remote GitLab repository in discrete, user-configured line increments across multiple commits.

## Features
- **Zero JSON**: Everything (runtime state, cursor, compulsory tags, phrases, and co-authors) is unified into a single human-friendly `config.toon` file.
- **Hardware-Locked Security**: The GitLab Personal Access Token (PAT) is encrypted via Windows DPAPI bound to the `LocalMachine`. It cannot be decrypted if copied to any other machine or PC.
- **Universal GitLab Compatibility**: Works with public `gitlab.com` as well as corporate internal enterprise GitLab instances (handles corporate proxies via `-UseDefaultCredentials` and internal CA/self-signed certificates).
- **PowerShell 5.1 URI Bug Fix**: Uses numeric project ID lookup to completely bypass the .NET `%2F` URL parser bug.
- **Transactional State Management**: Updates line cursor in `config.toon` only after a commit is confirmed by the GitLab API.

## File Structure
- `auto_committer.bat`: Double-click launcher for Windows.
- `auto_committer.ps1`: Core operational PowerShell script.
- `config.toon`: Unified configuration file containing state, cursor, and commit message sections.
- `source.txt`: The source code payload to commit in increments.

## Quick Start
1. Double-click `auto_committer.bat`.
2. Enter your GitLab Personal Access Token (PAT) and the target GitLab file URL.
3. Configure the number of commits and lines per commit.
4. Paste your code into `source.txt` and launch whenever you want to commit batches.
