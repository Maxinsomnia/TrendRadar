# TrendRadar Git Sync Strategy

## Goal
Establish a workflow to maintain local configurations (e.g., local AI models, `host.docker.internal` ports) on a `local` branch while syncing core logic and platform changes to the `master` branch for GitHub Actions.

## Current State
- You have uncommitted changes on the `master` branch containing local configurations.

## Implementation Steps

### Phase 1: Establish the `local` branch
1. Create and checkout a new branch named `local` from the current state.
2. Commit all currently uncommitted changes (platform additions, `config.yaml` modifications, prompt updates) to this `local` branch. This branch will now serve as your primary development branch.

### Phase 2: Prepare the `master` branch
1. Checkout the `master` branch.
2. Rebase `master` onto the `local` branch to inherit all new logic and platforms.
3. Perform a "purification" commit on `master` to revert local-specific configurations:
   - Disable RSS feeds relying on `host.docker.internal:1200`.
   - Set AI modes to disabled (`ai_analysis.enabled: false`, `ai_translation.enabled: false`).
   - Set filter method to `keyword`.
   - Clear the `api_base` for the AI model to revert to default remote endpoints.
   - Clear webhook URLs (relying on GitHub Secrets instead).

### Phase 3: Create the Sync Script
1. Switch back to the `local` branch.
2. Create a bash script `sync_to_master.sh` that automates this process for future updates.
   - The script will:
     - Check out `master`.
     - Rebase `master` onto `local`.
     - Use `sed` or `yq` (via a python script for reliability) to apply the "purification" changes to `config.yaml`.
     - Commit the purification changes.
     - Push `master` to the remote repository.
     - Switch back to `local`.

## Next Steps
Once you approve this plan, I will exit Plan Mode and execute these steps.