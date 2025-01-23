#!/bin/bash
set -eou pipefail

envfile=$(readlink -f ../.env)
export envfile
echo "Envfile = $envfile"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
export TIMESTAMP
LOG_FILE="upgrade_${TIMESTAMP}.log"

# Check for required command
if ! command -v upgrade-assistant &> /dev/null; then
    echo "ERROR: upgrade-assistant not found. Install with: dotnet tool install -g upgrade-assistant"
    exit 1
fi

if ! command -v aider &> /dev/null; then
    echo "ERROR: aider not found. Install with: pip install aider-chat"
    exit 1
fi

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}
export -f log

log "Starting .NET upgrade process"
log "Detected $(find Projects -maxdepth 2 -name '*.csproj' | wc -l) projects to upgrade"

# Use parallel processing with xargs
find Projects -maxdepth 2 -type f -name '*.csproj' -print0 | \
    xargs -0 -P 4 -I {} bash --login -c '
        csproj="$1"
        project_name=$(basename "$csproj" .csproj)
        log_dir="$(pwd)/upgrade_logs/${TIMESTAMP}/${project_name}"
        mkdir -p "$log_dir"
        
        # Add diagnostics
        echo "DEBUG: envfile=$envfile" | tee "${log_dir}/diagnostics.txt"
        echo "DEBUG: TIMESTAMP=$TIMESTAMP" | tee -a "${log_dir}/diagnostics.txt"
        echo "DEBUG: pwd=$(pwd)" | tee -a "${log_dir}/diagnostics.txt"
        
        log "Upgrading $csproj - logging to $log_dir"
        set +e
        upgrade-assistant upgrade --non-interactive -o InPlace -f net9.0 "$csproj" 2>&1 | tee "$log_dir/console.txt"
        exit_code=${PIPESTATUS[0]}
        set -e
        
        if [ $exit_code -eq 0 ]; then
            log "SUCCESS: $csproj upgraded successfully"
        else
            log "WARNING: $csproj upgrade failed (exit code $exit_code) - check $log_dir/console.txt"
        fi
        
        # Always invoke aider for review regardless of success/failure
        log "Running aider review for $csproj"
        (log "Invoking aider for $csproj";
         cd "$(dirname "$csproj")" && \
         aider --env-file "$envfile" --message "Review upgrade-assistant output (exit code $exit_code) and apply necessary code changes" \
           --read "${log_dir}/console.txt" 2>&1 | tee "${log_dir}/aider.txt") || true
        log "Aider review completed for $csproj - output in ${log_dir}/aider.txt"
    ' _ {} 

log "Upgrade process completed successfully. Review logs in upgrade_logs/${TIMESTAMP}/"
