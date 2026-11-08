# GitLab Batch Committer

A lightweight, portable Git automation tool designed for Windows and corporate VDI environments. It commits code from a local source text file into a remote GitLab repository in discrete, user-configured line increments across multiple commits.

## Features
- **Universal Compatibility**: Works with public `gitlab.com` as well as corporate internal enterprise GitLab instances (handles corporate proxies via `-UseDefaultCredentials` and internal CA/self-signed certificates).
- **No Compiled Binaries / No `.exe`**: Requires zero external compilers or third-party wrappers, compliant with corporate VDI execution policies.
- **PowerShell 5.1 URI Bug Fix**: Uses numeric project ID lookup to completely bypass the .NET `%2F` URL parser bug.
- **Human-Friendly Commit Configuration (`phrases.toon`)**: Easily configure compulsory Jira tags/prefixes and custom random phrases without dealing with fragile JSON syntax.
- **Transactional State Management**: Updates line cursor in `state.json` only after a commit is confirmed by the GitLab API.

## File Structure
- `auto_committer.bat`: Double-click launcher for Windows.
- `auto_committer.ps1`: Core operational PowerShell script.
- `phrases.toon`: Human-editable commit message templates and random phrase pool.
- `source.txt`: The source code payload to commit in increments.
- `state.json`: Auto-generated runtime state tracking your PAT, target URL, and current line cursor.

## Quick Start
1. Double-click `auto_committer.bat`.
2. Enter your GitLab Personal Access Token (PAT) and the target GitLab file URL.
3. Configure the number of commits and lines per commit.
4. Edit `phrases.toon` to set your desired Jira prefix and custom commit messages.
5. Paste your code into `source.txt` and launch whenever you want to commit batches.
