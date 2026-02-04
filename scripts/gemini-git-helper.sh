#!/bin/bash

# gemini-git-helper.sh
# Enhanced git helper that uses Gemini AI to:
# - Analyze all changes (staged, unstaged, untracked)
# - Detect sensitive content before committing
# - Validate .gitignore/.dockerignore patterns
# - Suggest commits grouped by topic

set -e
set -o pipefail

# --- Configuration ---
OAUTH_CREDS_FILE="/home/max/.gemini/oauth_creds.json"
GEMINI_API_BASE="https://generativelanguage.googleapis.com/v1beta/models"
USE_LOCAL_ONLY=false  # Set to true with --local flag
SCAN_HISTORY=false    # Set to true with --scan-history flag
PRE_COMMIT_MODE=false # Set to true with --pre-commit flag (secrets-only scan)
PRE_PUSH_MODE=false   # Set to true with --pre-push flag (scan commits being pushed)
PRE_PUSH_RANGE=""     # Commit range for pre-push scan
HISTORY_COMMITS=50    # Default number of commits to scan
HISTORY_SINCE=""      # Scan since this ref (branch/tag/commit)
SCAN_ALL_HISTORY=false # Scan entire history
# Models to try in order (fallback if quota exceeded)
GEMINI_MODELS=("gemini-2.5-flash" "gemini-2.5-pro" "gemini-2.0-flash" "gemini-2.0-flash-lite")
# API key from environment variable ONLY - no hardcoded fallbacks!
# Set with: export GEMINI_API_KEY='your-key-here'
GEMINI_API_KEYS=("${GEMINI_API_KEY:-}")
AUTH_METHOD=""  # Will be set to "api_key" or "oauth"
ACTIVE_API_KEY=""  # The key that worked

# --- Colors for output ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Pre-flight self-check: ensure this script doesn't contain hardcoded secrets ---
check_self_for_secrets() {
    local script_path="${BASH_SOURCE[0]}"
    local found_secrets=false

    # Check for Google API keys (excluding pattern definitions and this function)
    if grep -E 'AIza[0-9A-Za-z_-]{35}' "$script_path" 2>/dev/null | grep -v "AIza\[0-9A-Za-z" | grep -qv 'check_self_for_secrets'; then
        echo -e "${RED}CRITICAL: Hardcoded Google API key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for AWS keys
    if grep -qE 'AKIA[0-9A-Z]{16}' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded AWS key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for GitHub tokens (all types: ghp_, gho_, ghu_, ghs_, ghr_)
    if grep -qE 'gh[pousr]_[0-9a-zA-Z]{36}' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded GitHub token detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for Stripe keys
    if grep -qE '[sp]k_live_[0-9a-zA-Z]{24}' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded Stripe key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for Slack tokens
    if grep -qE 'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded Slack token detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for SendGrid keys
    if grep -qE 'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded SendGrid key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for Twilio keys
    if grep -qE 'SK[0-9a-fA-F]{32}' "$script_path" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Hardcoded Twilio key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for private keys (exclude pattern definitions - lines starting with single quote)
    if grep -E 'BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY' "$script_path" 2>/dev/null | grep -qvE "^[[:space:]]*'"; then
        echo -e "${RED}CRITICAL: Hardcoded private key detected!${NC}" >&2
        found_secrets=true
    fi

    # Check for JWT tokens (excluding pattern definitions)
    if grep -E 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*' "$script_path" 2>/dev/null | grep -qv 'eyJ\[A-Za-z0-9'; then
        echo -e "${RED}CRITICAL: Hardcoded JWT token detected!${NC}" >&2
        found_secrets=true
    fi

    if [[ "$found_secrets" == "true" ]]; then
        echo -e "${RED}Remove hardcoded secrets before using this script!${NC}" >&2
        echo -e "${YELLOW}Use environment variables instead: export GEMINI_API_KEY='your-key'${NC}" >&2
        exit 1
    fi
}

# Run self-check immediately
check_self_for_secrets

# --- Sensitive content patterns ---
SENSITIVE_PATTERNS=(
    # AWS
    'AKIA[0-9A-Z]{16}'
    'aws_access_key_id\s*=\s*["\047]?[A-Z0-9]{20}'
    'aws_secret_access_key\s*=\s*["\047]?[A-Za-z0-9/+=]{40}'

    # Google
    'AIza[0-9A-Za-z\-_]{35}'
    'ya29\.[0-9A-Za-z\-_]+'

    # GitHub
    'ghp_[0-9a-zA-Z]{36}'
    'gho_[0-9a-zA-Z]{36}'
    'ghu_[0-9a-zA-Z]{36}'
    'ghs_[0-9a-zA-Z]{36}'
    'ghr_[0-9a-zA-Z]{36}'
    'github_pat_[0-9a-zA-Z_]{22,}'

    # Generic secrets
    'private_key'
    'BEGIN RSA PRIVATE KEY'
    'BEGIN OPENSSH PRIVATE KEY'
    'BEGIN EC PRIVATE KEY'
    'BEGIN PGP PRIVATE KEY'

    # API keys and tokens (generic)
    '[aA][pP][iI]_?[kK][eE][yY]\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}'
    '[aA][pP][iI]_?[sS][eE][cC][rR][eE][tT]\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}'
    '[sS][eE][cC][rR][eE][tT]_?[kK][eE][yY]\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}'
    '[aA][cC][cC][eE][sS][sS]_?[tT][oO][kK][eE][nN]\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}'

    # Passwords
    '[pP][aA][sS][sS][wW][oO][rR][dD]\s*[=:]\s*["\047][^"\047]{8,}["\047]'
    '[pP][aA][sS][sS][wW][dD]\s*[=:]\s*["\047][^"\047]{8,}["\047]'

    # Database URLs with credentials
    '(mysql|postgresql|postgres|mongodb|redis):\/\/[^:]+:[^@]+@'

    # JWT tokens
    'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'

    # Slack
    'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*'

    # Stripe
    'sk_live_[0-9a-zA-Z]{24}'
    'pk_live_[0-9a-zA-Z]{24}'

    # Twilio
    'SK[0-9a-fA-F]{32}'

    # SendGrid
    'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}'
)

# --- Required patterns for .gitignore ---
REQUIRED_GITIGNORE_PATTERNS=(
    '.env'
    '.env.local'
    '.env*.local'
    '*.pem'
    '*.key'
    'credentials.json'
    'oauth_creds.json'
    'secrets.json'
    '*.secret'
    'id_rsa'
    'id_ed25519'
)

# --- Required patterns for .dockerignore ---
REQUIRED_DOCKERIGNORE_PATTERNS=(
    '.env'
    '.env.local'
    '*.pem'
    '*.key'
    '.git'
    'node_modules'
    '.env*.local'
)

# --- Functions ---

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
}

print_error() {
    echo -e "${RED}✗ ERROR:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Detect available secret scanner tool
detect_scanner_tool() {
    if command -v gitleaks &> /dev/null; then
        SCANNER_TOOL="gitleaks"
        SCANNER_VERSION=$(gitleaks version 2>/dev/null | head -1 || echo "unknown")
    elif command -v trufflehog &> /dev/null; then
        SCANNER_TOOL="trufflehog"
        SCANNER_VERSION=$(trufflehog --version 2>/dev/null | head -1 || echo "unknown")
    else
        SCANNER_TOOL="native"
        SCANNER_VERSION="built-in"
    fi
    # Always return 0 - the caller checks SCANNER_TOOL variable
    return 0
}

# Prompt user to install a scanner tool
prompt_install_scanner() {
    echo ""
    print_warning "No secret scanner found. Install gitleaks for best results:"
    echo ""
    echo "  # Linux (apt)"
    echo "  sudo apt install gitleaks"
    echo ""
    echo "  # Linux (snap)"
    echo "  sudo snap install gitleaks"
    echo ""
    echo "  # macOS (brew)"
    echo "  brew install gitleaks"
    echo ""
    echo "  # Or download from: https://github.com/gitleaks/gitleaks/releases"
    echo ""
    read -p "Continue with native (grep-based) scanning? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted. Install gitleaks and try again."
        exit 0
    fi
}

# Scan with gitleaks
scan_with_gitleaks() {
    local log_opts=""

    if [ "$SCAN_ALL_HISTORY" = true ]; then
        log_opts="--all"
    elif [ -n "$HISTORY_SINCE" ]; then
        log_opts="${HISTORY_SINCE}..HEAD"
    else
        log_opts="-n ${HISTORY_COMMITS}"
    fi

    print_info "Running: gitleaks detect --source . --log-opts=\"$log_opts\" -v"

    # Run gitleaks and capture output
    local output
    local exit_code=0

    output=$(gitleaks detect --source . --log-opts="$log_opts" -v 2>&1) || exit_code=$?

    # Check if it's a git error (empty repo, no commits) vs actual secrets found
    if echo "$output" | grep -q "no leaks found"; then
        # No secrets, even if exit code is non-zero due to git warnings
        if echo "$output" | grep -q "partial scan\|git error"; then
            print_warning "Scan completed with warnings (check output below)"
            echo "$output" | grep -E "(ERR|WRN)" | head -5
        fi
        print_success "No secrets found in commit history"
        HISTORY_SECRETS_FOUND=false
        return 0
    elif [ "$exit_code" -eq 0 ]; then
        print_success "No secrets found in commit history"
        HISTORY_SECRETS_FOUND=false
        return 0
    else
        # Actual secrets found
        echo ""
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⚠️  SECRETS FOUND IN COMMIT HISTORY!                       ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "$output"
        HISTORY_SECRETS_FOUND=true
        HISTORY_SECRETS_OUTPUT="$output"
        return 1
    fi
}

# Scan with trufflehog
scan_with_trufflehog() {
    local scan_args="git file://."

    if [ -n "$HISTORY_SINCE" ]; then
        scan_args+=" --since-commit $HISTORY_SINCE"
    fi

    # Note: trufflehog doesn't have a simple --commits flag, it scans what it finds
    scan_args+=" --results=verified,unknown"

    print_info "Running: trufflehog $scan_args"

    # Run trufflehog and capture output
    local output
    local exit_code

    output=$(trufflehog $scan_args 2>&1) || exit_code=$?

    if [ -z "$output" ] || [ "$output" = "{}" ]; then
        print_success "No secrets found in commit history"
        HISTORY_SECRETS_FOUND=false
        return 0
    else
        echo ""
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⚠️  SECRETS FOUND IN COMMIT HISTORY!                       ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "$output"
        HISTORY_SECRETS_FOUND=true
        HISTORY_SECRETS_OUTPUT="$output"
        return 1
    fi
}

# Native fallback scanner using git log and grep
scan_with_native() {
    print_info "Using native grep-based scanning (less accurate than gitleaks)"

    local git_log_args="-p"

    if [ "$SCAN_ALL_HISTORY" = true ]; then
        git_log_args+=" --all"
    elif [ -n "$HISTORY_SINCE" ]; then
        git_log_args+=" ${HISTORY_SINCE}..HEAD"
    else
        git_log_args+=" -n ${HISTORY_COMMITS}"
    fi

    print_info "Scanning commits with: git log $git_log_args"

    local found_secrets=false
    local secrets_report=""
    local current_commit=""
    local current_file=""
    local line_num=0

    # Build combined pattern for efficiency
    local combined_pattern=""
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if [ -n "$combined_pattern" ]; then
            combined_pattern+="|"
        fi
        combined_pattern+="$pattern"
    done

    # Scan git log output
    local temp_file=$(mktemp)
    git log $git_log_args > "$temp_file" 2>/dev/null

    # Process line by line to track context
    while IFS= read -r line; do
        # Track commit
        if [[ "$line" =~ ^commit\ ([a-f0-9]+) ]]; then
            current_commit="${BASH_REMATCH[1]:0:8}"
            continue
        fi

        # Track file
        if [[ "$line" =~ ^diff\ --git\ a/(.+)\ b/ ]]; then
            current_file="${BASH_REMATCH[1]}"
            line_num=0
            continue
        fi

        # Track line numbers in diff
        if [[ "$line" =~ ^@@.*\+([0-9]+) ]]; then
            line_num="${BASH_REMATCH[1]}"
            continue
        fi

        # Check for added lines (+ prefix in diff)
        if [[ "$line" =~ ^\+ ]]; then
            # Check against patterns
            for pattern in "${SENSITIVE_PATTERNS[@]}"; do
                if echo "$line" | grep -qE "$pattern" 2>/dev/null; then
                    # Skip if it's a placeholder/template value
                    if echo "$line" | grep -qE '(your_|changeme|placeholder|CHANGEME|YOUR_|xxx|XXX|<.*>|\$\{)'; then
                        continue
                    fi

                    found_secrets=true
                    secrets_report+="${RED}✗ SECRET FOUND${NC}\n"
                    secrets_report+="  Commit: $current_commit\n"
                    secrets_report+="  File: $current_file\n"
                    secrets_report+="  Line: ~$line_num\n"
                    secrets_report+="  Pattern: $pattern\n"
                    secrets_report+="  Content: [REDACTED]\n\n"
                    break
                fi
            done
            ((line_num++)) || true
        fi
    done < "$temp_file"

    rm -f "$temp_file"

    if [ "$found_secrets" = true ]; then
        echo ""
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⚠️  SECRETS FOUND IN COMMIT HISTORY!                       ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "$secrets_report"
        HISTORY_SECRETS_FOUND=true
        HISTORY_SECRETS_OUTPUT="$secrets_report"
        return 1
    else
        print_success "No secrets found in commit history"
        HISTORY_SECRETS_FOUND=false
        return 0
    fi
}

# Main history scanning function
scan_commit_history() {
    print_header "Scanning Commit History"

    # Show what we're scanning
    if [ "$SCAN_ALL_HISTORY" = true ]; then
        print_info "Scanning: entire git history"
    elif [ -n "$HISTORY_SINCE" ]; then
        print_info "Scanning: commits since $HISTORY_SINCE"
    else
        print_info "Scanning: last $HISTORY_COMMITS commits"
    fi

    # Detect scanner tool
    detect_scanner_tool

    # If no external scanner, prompt to install or continue with native
    if [ "$SCANNER_TOOL" = "native" ]; then
        prompt_install_scanner
    fi

    print_info "Using scanner: $SCANNER_TOOL ($SCANNER_VERSION)"
    echo ""

    # Run appropriate scanner
    local scan_result=0
    case "$SCANNER_TOOL" in
        gitleaks)
            scan_with_gitleaks || scan_result=$?
            ;;
        trufflehog)
            scan_with_trufflehog || scan_result=$?
            ;;
        native)
            scan_with_native || scan_result=$?
            ;;
    esac

    # Show remediation advice if secrets found
    if [ "$HISTORY_SECRETS_FOUND" = true ]; then
        echo ""
        print_header "Remediation Steps"
        echo "To remove secrets from git history, consider:"
        echo ""
        echo "  1. BFG Repo-Cleaner (recommended, fast):"
        echo "     https://rtyley.github.io/bfg-repo-cleaner/"
        echo "     bfg --replace-text passwords.txt repo.git"
        echo ""
        echo "  2. git filter-repo (more flexible):"
        echo "     https://github.com/newren/git-filter-repo"
        echo "     git filter-repo --replace-text expressions.txt"
        echo ""
        echo "  3. Rotate/revoke the exposed credentials immediately!"
        echo ""
        print_warning "After cleaning history, force-push and notify collaborators."
        return 1
    fi

    return 0
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_error "Not a git repository."
        exit 1
    fi
    print_success "Git repository detected: $(basename $(git rev-parse --show-toplevel))"
}

# Check API keys are available
check_api_keys() {
    # API key MUST be set via environment variable - no hardcoded fallbacks!
    if [ -z "${GEMINI_API_KEY:-}" ]; then
        print_error "GEMINI_API_KEY environment variable not set!"
        echo ""
        echo "Please set up an API key:"
        echo "  export GEMINI_API_KEY='your-api-key'"
        echo "  Get a key at: https://aistudio.google.com/app/apikey"
        echo ""
        echo "Or use --local mode for offline analysis (no API needed):"
        echo "  $(basename "$0") --local"
        echo ""
        exit 1
    fi

    print_success "API key found in environment"
}

# Collect all git changes
collect_git_changes() {
    print_header "Collecting Git Changes"

    local changes=""

    # 1. Staged changes (to be committed)
    STAGED_DIFF=$(git diff --cached 2>/dev/null || true)
    if [ -n "$STAGED_DIFF" ]; then
        changes+="=== STAGED CHANGES (will be committed) ===\n"
        changes+="$STAGED_DIFF\n\n"
        print_info "Found staged changes"
    fi

    # 2. Unstaged changes (modified but not staged)
    UNSTAGED_DIFF=$(git diff 2>/dev/null || true)
    if [ -n "$UNSTAGED_DIFF" ]; then
        changes+="=== UNSTAGED CHANGES (modified, not staged) ===\n"
        changes+="$UNSTAGED_DIFF\n\n"
        print_info "Found unstaged changes"
    fi

    # 3. Untracked files
    UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || true)
    if [ -n "$UNTRACKED_FILES" ]; then
        changes+="=== UNTRACKED FILES (new files) ===\n"
        changes+="$UNTRACKED_FILES\n\n"

        # Show content preview of small untracked files
        changes+="=== UNTRACKED FILES CONTENT PREVIEW ===\n"
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                FILE_SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
                if [ "$FILE_SIZE" -lt 10000 ]; then
                    changes+="--- $file ---\n"
                    changes+="$(cat "$file" 2>/dev/null | head -100)\n"
                    changes+="[... truncated if longer ...]\n\n"
                else
                    changes+="--- $file --- (file too large, $FILE_SIZE bytes)\n\n"
                fi
            fi
        done <<< "$UNTRACKED_FILES"
        print_info "Found $(echo "$UNTRACKED_FILES" | wc -l) untracked files"
    fi

    # 4. Git status summary
    GIT_STATUS=$(git status --short 2>/dev/null || true)
    if [ -n "$GIT_STATUS" ]; then
        changes+="=== GIT STATUS SUMMARY ===\n"
        changes+="$GIT_STATUS\n"
    fi

    if [ -z "$STAGED_DIFF" ] && [ -z "$UNSTAGED_DIFF" ] && [ -z "$UNTRACKED_FILES" ]; then
        print_success "No changes to commit."
        exit 0
    fi

    ALL_CHANGES="$changes"
}

# Scan for sensitive content
scan_sensitive_content() {
    print_header "Scanning for Sensitive Content"

    local found_secrets=false
    local secrets_report=""

    # Get all changed/new file content
    local files_to_scan=""

    # Staged files
    files_to_scan+=$(git diff --cached --name-only 2>/dev/null || true)
    files_to_scan+=$'\n'

    # Unstaged modified files
    files_to_scan+=$(git diff --name-only 2>/dev/null || true)
    files_to_scan+=$'\n'

    # Untracked files
    files_to_scan+=$(git ls-files --others --exclude-standard 2>/dev/null || true)

    # Remove duplicates and empty lines
    files_to_scan=$(echo "$files_to_scan" | sort -u | grep -v '^$' || true)

    if [ -z "$files_to_scan" ]; then
        print_success "No files to scan"
        return 0
    fi

    echo "Scanning $(echo "$files_to_scan" | wc -l) files for sensitive content..."

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        # Skip binary files
        if file "$file" | grep -q "binary"; then
            continue
        fi

        # Skip this script itself (contains patterns for legitimate reasons)
        if [[ "$(basename "$file")" == "gemini-git-helper.sh" ]]; then
            continue
        fi

        # Skip template files with placeholder values (common false positives)
        local is_template=false
        if [[ "$file" == *".template"* ]] || [[ "$file" == *".example"* ]] || [[ "$file" == *".sample"* ]]; then
            is_template=true
        fi

        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
            if [ -n "$matches" ]; then
                # For template files, check if it's an actual secret or just a placeholder
                if [ "$is_template" = true ]; then
                    # Skip if the line contains placeholder indicators
                    if echo "$matches" | grep -qE '(your_|changeme|placeholder|CHANGEME|YOUR_|xxx|XXX|<.*>|\$\{)'; then
                        continue
                    fi
                fi

                found_secrets=true
                secrets_report+="${RED}Found in $file:${NC}\n"
                secrets_report+="  Pattern: $pattern\n"
                # Mask the actual secret value
                while IFS= read -r match; do
                    line_num=$(echo "$match" | cut -d: -f1)
                    secrets_report+="  Line $line_num: [SENSITIVE CONTENT DETECTED]\n"
                done <<< "$matches"
                secrets_report+="\n"
            fi
        done
    done <<< "$files_to_scan"

    if [ "$found_secrets" = true ]; then
        print_error "SENSITIVE CONTENT DETECTED!"
        echo -e "$secrets_report"
        SENSITIVE_FOUND=true
        SENSITIVE_REPORT="$secrets_report"
    else
        print_success "No sensitive content detected"
        SENSITIVE_FOUND=false
    fi
}

# Local commit message generation (fallback when API unavailable)
generate_local_commit_suggestion() {
    print_header "Local Commit Analysis (No API)"

    # Get change status
    local staged_status=$(git diff --cached --name-status 2>/dev/null || true)
    local unstaged_status=$(git diff --name-status 2>/dev/null || true)
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null || true)

    if [ -z "$staged_status" ] && [ -z "$unstaged_status" ] && [ -z "$untracked" ]; then
        print_info "No changes to analyze"
        return
    fi

    # Count changes (handle empty input properly)
    local added=0
    local modified=0
    local deleted=0

    if [ -n "$staged_status" ]; then
        added=$(echo "$staged_status" | grep -c "^A" || true)
        modified=$(echo "$staged_status" | grep -c "^M" || true)
        deleted=$(echo "$staged_status" | grep -c "^D" || true)
    fi

    # Ensure they are integers
    added=${added:-0}
    modified=${modified:-0}
    deleted=${deleted:-0}

    # Get diff content for analysis
    local diff_content=$(git diff --cached 2>/dev/null || true)
    [ -z "$diff_content" ] && diff_content=$(git diff 2>/dev/null || true)

    # Detect commit type
    local commit_type="feat"

    # Check for documentation
    if echo "$staged_status$unstaged_status$untracked" | grep -qE '\.(md|txt|rst|doc)$'; then
        commit_type="docs"
    fi

    # Check for tests
    if echo "$staged_status$unstaged_status$untracked" | grep -qiE '(test|spec|__tests__)'; then
        commit_type="test"
    fi

    # Check for fix indicators
    if echo "$diff_content" | grep -qiE '\b(fix|bug|error|issue|patch|hotfix|correct)\b'; then
        commit_type="fix"
    fi

    # Check for refactoring
    if echo "$diff_content" | grep -qiE '\b(refactor|restructure|reorganize|cleanup)\b'; then
        commit_type="refactor"
    fi

    # Check for config/chore
    if echo "$staged_status$unstaged_status$untracked" | grep -qE '(\.config\.|package\.json|\.yml|\.yaml|Makefile|Dockerfile)'; then
        commit_type="chore"
    fi

    # Determine scope from directories
    local all_files=$(echo -e "$staged_status\n$unstaged_status" | awk '{print $2}' | grep -v '^$' || true)
    [ -z "$all_files" ] && all_files="$untracked"

    local dirs=$(echo "$all_files" | xargs -I{} dirname {} 2>/dev/null | sort -u | head -3)
    local dir_count=$(echo "$dirs" | grep -c . 2>/dev/null || echo 0)

    local scope=""
    if [ "$dir_count" -eq 1 ]; then
        scope=$(echo "$dirs" | head -1)
        [ "$scope" = "." ] && scope=""
    fi

    # Generate description based on file analysis
    local desc=""
    local staged_files=$(echo "$staged_status" | awk '{print $2}' | grep -v '^$' || true)

    # Analyze what types of files changed
    local has_config=false
    local has_docker=false
    local has_env=false
    local has_docs=false
    local has_scripts=false

    if echo "$staged_files" | grep -qE '(\.yml|\.yaml|\.json|\.conf|\.ini|\.config)$'; then
        has_config=true
    fi
    if echo "$staged_files" | grep -qiE '(docker|compose)'; then
        has_docker=true
    fi
    if echo "$staged_files" | grep -qE '(\.env|env\.template)'; then
        has_env=true
    fi
    if echo "$staged_files" | grep -qE '(\.md|docs/)'; then
        has_docs=true
    fi
    if echo "$staged_files" | grep -qE '(\.sh|scripts/)'; then
        has_scripts=true
    fi

    # Build descriptive message based on what changed
    if [ "$added" -gt 0 ] && [ "$modified" -eq 0 ]; then
        if [ "$added" -eq 1 ]; then
            local file=$(echo "$staged_status" | grep "^A" | head -1 | awk '{print $2}')
            desc="add $(basename "$file")"
        else
            desc="add $added new files"
        fi
    elif [ "$modified" -gt 0 ] && [ "$added" -eq 0 ]; then
        if [ "$modified" -eq 1 ]; then
            local file=$(echo "$staged_status" | grep "^M" | head -1 | awk '{print $2}')
            desc="update $(basename "$file")"
        elif [ "$has_docker" = true ] && [ "$has_env" = true ]; then
            desc="update Docker and environment configuration"
        elif [ "$has_docker" = true ]; then
            desc="update Docker configuration"
        elif [ "$has_config" = true ]; then
            desc="update configuration files"
        elif [ "$has_env" = true ]; then
            desc="update environment template"
        elif [ "$has_docs" = true ]; then
            desc="update documentation"
        elif [ "$has_scripts" = true ]; then
            desc="update scripts"
        else
            desc="update $modified files"
        fi
    elif [ "$deleted" -gt 0 ] && [ "$added" -eq 0 ] && [ "$modified" -eq 0 ]; then
        desc="remove $deleted files"
    else
        # Mixed changes
        local parts=()
        [ "$added" -gt 0 ] && parts+=("add $added")
        [ "$modified" -gt 0 ] && parts+=("update $modified")
        [ "$deleted" -gt 0 ] && parts+=("remove $deleted")

        if [ "$has_docker" = true ]; then
            desc="update Docker setup"
        elif [ "$has_config" = true ]; then
            desc="update configuration"
        else
            desc="${parts[*]} files"
        fi
    fi

    # Build commit message
    local commit_msg=""
    if [ -n "$scope" ]; then
        commit_msg="${commit_type}(${scope}): ${desc}"
    else
        commit_msg="${commit_type}: ${desc}"
    fi

    echo ""
    echo -e "${GREEN}## Local Commit Suggestion${NC}"
    echo ""
    echo "Based on local analysis of your changes:"
    echo ""

    if [ -n "$staged_status" ]; then
        echo -e "${BLUE}Staged changes:${NC}"
        echo "$staged_status" | while read -r line; do
            local status=$(echo "$line" | cut -c1)
            local file=$(echo "$line" | awk '{print $2}')
            case $status in
                A) echo "  + $file (added)" ;;
                M) echo "  ~ $file (modified)" ;;
                D) echo "  - $file (deleted)" ;;
                R) echo "  > $file (renamed)" ;;
                *) echo "  * $file" ;;
            esac
        done
        echo ""
        echo -e "${GREEN}Suggested commit:${NC}"
        echo -e "  git commit -m \"$commit_msg\""
    else
        echo -e "${YELLOW}No staged changes.${NC} Stage files first:"
        if [ -n "$unstaged_status" ]; then
            echo "  git add <files>  # for modified files"
        fi
        if [ -n "$untracked" ]; then
            echo "  git add <files>  # for new files"
        fi
        echo ""
        echo -e "${GREEN}Then commit with:${NC}"
        echo -e "  git commit -m \"$commit_msg\""
    fi

    echo ""
    echo -e "${YELLOW}Note:${NC} This is a basic suggestion. For better analysis, ensure API keys are configured."
    echo "      Change summary: +$added added, ~$modified modified, -$deleted deleted"

    LOCAL_SUGGESTION="$commit_msg"
}

# Check .gitignore patterns
check_gitignore() {
    print_header "Validating .gitignore"

    local missing_patterns=()
    local gitignore_file=".gitignore"

    if [ ! -f "$gitignore_file" ]; then
        print_warning ".gitignore file not found!"
        GITIGNORE_MISSING=true
        GITIGNORE_SUGGESTIONS="${REQUIRED_GITIGNORE_PATTERNS[*]}"
        return
    fi

    for pattern in "${REQUIRED_GITIGNORE_PATTERNS[@]}"; do
        if ! grep -qF "$pattern" "$gitignore_file" 2>/dev/null; then
            missing_patterns+=("$pattern")
        fi
    done

    if [ ${#missing_patterns[@]} -gt 0 ]; then
        print_warning "Missing recommended patterns in .gitignore:"
        for pattern in "${missing_patterns[@]}"; do
            echo "  - $pattern"
        done
        GITIGNORE_MISSING_PATTERNS="${missing_patterns[*]}"
    else
        print_success ".gitignore has all recommended security patterns"
        GITIGNORE_MISSING_PATTERNS=""
    fi
}

# Check .dockerignore patterns
check_dockerignore() {
    print_header "Validating .dockerignore"

    local missing_patterns=()
    local dockerignore_file=".dockerignore"

    # Check if there's a Dockerfile
    if [ ! -f "Dockerfile" ] && [ ! -f "dockerfile" ]; then
        print_info "No Dockerfile found, skipping .dockerignore check"
        DOCKERIGNORE_MISSING_PATTERNS=""
        return
    fi

    if [ ! -f "$dockerignore_file" ]; then
        print_warning ".dockerignore file not found (but Dockerfile exists)!"
        DOCKERIGNORE_MISSING=true
        DOCKERIGNORE_SUGGESTIONS="${REQUIRED_DOCKERIGNORE_PATTERNS[*]}"
        return
    fi

    for pattern in "${REQUIRED_DOCKERIGNORE_PATTERNS[@]}"; do
        if ! grep -qF "$pattern" "$dockerignore_file" 2>/dev/null; then
            missing_patterns+=("$pattern")
        fi
    done

    if [ ${#missing_patterns[@]} -gt 0 ]; then
        print_warning "Missing recommended patterns in .dockerignore:"
        for pattern in "${missing_patterns[@]}"; do
            echo "  - $pattern"
        done
        DOCKERIGNORE_MISSING_PATTERNS="${missing_patterns[*]}"
    else
        print_success ".dockerignore has all recommended security patterns"
        DOCKERIGNORE_MISSING_PATTERNS=""
    fi
}

# Escape string for JSON
json_escape() {
    local string="$1"
    # Use python for reliable JSON escaping
    python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$string" | sed 's/^"//;s/"$//'
}

# Call Gemini API
call_gemini_api() {
    print_header "Calling Gemini API"

    # Build context about security findings
    local security_context=""

    if [ "$SENSITIVE_FOUND" = true ]; then
        security_context+="CRITICAL SECURITY WARNING: Sensitive content was detected in the changes. DO NOT suggest committing files with secrets.\n\n"
    fi

    if [ -n "$GITIGNORE_MISSING_PATTERNS" ]; then
        security_context+="WARNING: .gitignore is missing these patterns: $GITIGNORE_MISSING_PATTERNS\n"
        security_context+="Suggest adding these patterns before committing.\n\n"
    fi

    if [ -n "$DOCKERIGNORE_MISSING_PATTERNS" ]; then
        security_context+="WARNING: .dockerignore is missing these patterns: $DOCKERIGNORE_MISSING_PATTERNS\n\n"
    fi

    # Construct the prompt
    local prompt_content="You are an expert software engineer analyzing git changes to suggest precise, meaningful commit messages.

SECURITY FINDINGS:
$security_context

TASK:
Analyze the following git changes thoroughly and provide:

1. SECURITY WARNINGS (if sensitive content detected):
   - Identify the exact files and what type of secret was found
   - Suggest how to secure it (env vars, .gitignore, etc.)

2. IGNORE FILE UPDATES (if needed):
   - Exact lines to add to .gitignore/.dockerignore

3. COMMIT SUGGESTIONS - This is the MOST IMPORTANT part:
   - Group logically related changes together
   - For EACH group, provide git add and commit commands

COMMIT MESSAGE RULES - FOLLOW THESE EXACTLY:
- Use conventional commits: type(scope): description
- Types: feat (new feature), fix (bug fix), refactor (restructuring), docs (documentation),
         chore (maintenance), test (tests), style (formatting), perf (performance)
- Scope: The component/module affected (e.g., auth, api, genymotion, setup)
- Description: MUST describe WHAT changed and WHY, not just list files
- Be SPECIFIC: \"feat(genymotion): add multi-path detection for installation\" NOT \"feat: add initial project structure\"
- Analyze the ACTUAL DIFF to understand what the code does, not just file names
- If modifying existing code: describe the improvement/fix
- If adding new code: describe the functionality added
- Keep under 72 characters but be descriptive

EXAMPLES OF GOOD VS BAD COMMIT MESSAGES:
❌ BAD:  \"feat: add initial project structure\"
❌ BAD:  \"fix: update file\"
❌ BAD:  \"chore: changes\"
✓ GOOD: \"feat(auth): add JWT token validation middleware\"
✓ GOOD: \"fix(api): handle null response in user lookup\"
✓ GOOD: \"refactor(setup): support multiple installation paths\"

GIT CHANGES TO ANALYZE:
$ALL_CHANGES

OUTPUT FORMAT (no extra text, just this structure):

## Security Warnings
[warnings or \"None\"]

## Ignore File Updates
[updates or \"None needed\"]

## Commits

### Group 1: [Descriptive Topic Name]
\`\`\`bash
git add file1 file2
git commit -m \"type(scope): specific description of what changed\"
\`\`\`

### Group 2: [Topic Name]
\`\`\`bash
git add file3
git commit -m \"type(scope): specific description\"
\`\`\`"

    # Escape the prompt for JSON
    local escaped_prompt
    escaped_prompt=$(json_escape "$prompt_content")

    # Build the request body
    local request_body
    request_body=$(cat <<EOF
{
  "contents": [
    {
      "parts": [
        {"text": "$escaped_prompt"}
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.2,
    "topK": 40,
    "topP": 0.95,
    "maxOutputTokens": 4096
  },
  "safetySettings": [
    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
  ]
}
EOF
)

    # Try each API key and model combination until one works
    local success=false

    # Build list of API keys to try (always use API keys, OAuth is unreliable for Gemini)
    local keys_to_try=()
    for key in "${GEMINI_API_KEYS[@]}"; do
        [ -n "$key" ] && keys_to_try+=("$key")
    done

    if [ ${#keys_to_try[@]} -eq 0 ]; then
        print_error "No API keys available"
        echo "Set GEMINI_API_KEY environment variable or add keys to the script"
        exit 1
    fi

    for api_key in "${keys_to_try[@]}"; do
        [ -z "$api_key" ] && continue

        local key_preview="${api_key:0:10}...${api_key: -4}"
        print_info "Trying API key: $key_preview"

        for model in "${GEMINI_MODELS[@]}"; do
            print_info "  → Model: $model"

            local api_url="${GEMINI_API_BASE}/${model}:generateContent"

            # Always use API key authentication for Gemini API
            API_RESPONSE=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d "$request_body" \
                "${api_url}?key=${api_key}")

            if [ $? -ne 0 ]; then
                print_warning "    cURL failed, trying next..."
                continue
            fi

            # Check for API errors
            local error_code
            error_code=$(echo "$API_RESPONSE" | jq -r '.error.code // empty' 2>/dev/null)

            if [ "$error_code" = "429" ]; then
                print_warning "    Quota exceeded, trying next..."
                continue
            elif [ "$error_code" = "403" ]; then
                local error_msg=$(echo "$API_RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
                if [[ "$error_msg" == *"leaked"* ]] || [[ "$error_msg" == *"invalid"* ]]; then
                    print_warning "    API key invalid/leaked, trying next key..."
                    break  # Skip to next API key
                fi
                print_warning "    Permission denied, trying next..."
                continue
            elif [ -n "$error_code" ]; then
                local error_message
                error_message=$(echo "$API_RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
                print_error "Gemini API error ($model): $error_message"
                continue
            fi

            # Extract the response text
            SUGGESTIONS=$(echo "$API_RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

            if [ -n "$SUGGESTIONS" ]; then
                print_success "Received response from $model"
                ACTIVE_API_KEY="$api_key"
                success=true
                break 2  # Break out of both loops
            fi
        done
    done

    if [ "$success" = false ]; then
        print_error "All API keys and models failed."
        echo "Try again later or check your API quota at https://ai.dev/rate-limit"
        return 1
    fi

    if [ -z "$SUGGESTIONS" ]; then
        print_error "Gemini API did not return suggestions."
        echo "Raw API response: $API_RESPONSE" >&2
        return 1
    fi

    print_success "Received response from Gemini"
    return 0
}

# Display results
display_results() {
    print_header "Gemini Suggestions"

    if [ "$SENSITIVE_FOUND" = true ]; then
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⚠️  SECURITY ALERT: Review sensitive content warnings!    ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    echo "$SUGGESTIONS"

    echo ""
    print_header "Next Steps"
    echo "1. Review the suggestions above carefully"
    echo "2. If sensitive content was found, secure it first"
    echo "3. Update .gitignore/.dockerignore if recommended"
    echo "4. Execute git commands one group at a time"
    echo "5. Review each commit before pushing"
    echo ""
    print_warning "Never commit sensitive data like API keys, passwords, or tokens!"
}

# --- Pre-push scan function ---
run_pre_push_scan() {
    local range="$1"

    # Detect scanner (gitleaks only for hooks - speed is critical)
    if command -v gitleaks &> /dev/null; then
        SCANNER_TOOL="gitleaks"
    else
        SCANNER_TOOL="native"
    fi

    local found_secrets=false

    if [ "$SCANNER_TOOL" = "gitleaks" ]; then
        # Use gitleaks for fast scanning
        local output
        local exit_code=0

        # For new branches, scan all commits; for existing, scan the range
        if [[ "$range" =~ \.\. ]]; then
            # Range format: remote_sha..local_sha
            output=$(gitleaks detect --source . --log-opts="$range" -v 2>&1) || exit_code=$?
        else
            # Single SHA (new branch) - scan that commit and its ancestors not on remote
            output=$(gitleaks detect --source . --log-opts="$range" -v 2>&1) || exit_code=$?
        fi

        # Check for secrets
        if echo "$output" | grep -q "no leaks found"; then
            found_secrets=false
        elif [ "$exit_code" -eq 0 ]; then
            found_secrets=false
        else
            # Actual secrets found
            echo -e "${RED}Secrets detected in commits being pushed:${NC}"
            echo "$output" | grep -E "(Secret|File|Commit|Line)" | head -20
            found_secrets=true
        fi
    else
        # Native fallback - scan diff of commits being pushed
        local temp_file=$(mktemp)

        if [[ "$range" =~ \.\. ]]; then
            git log -p "$range" > "$temp_file" 2>/dev/null
        else
            git log -p "$range" -n 50 > "$temp_file" 2>/dev/null
        fi

        # Build combined pattern
        local combined_pattern=""
        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            if [ -n "$combined_pattern" ]; then
                combined_pattern+="|"
            fi
            combined_pattern+="$pattern"
        done

        # Scan for patterns in added lines
        if grep -E "^\+" "$temp_file" 2>/dev/null | grep -qE "$combined_pattern" 2>/dev/null; then
            # Filter out placeholders
            local real_matches=$(grep -E "^\+" "$temp_file" 2>/dev/null | grep -E "$combined_pattern" 2>/dev/null | grep -vE '(your_|changeme|placeholder|CHANGEME|YOUR_|xxx|XXX|<.*>|\$\{)' || true)
            if [ -n "$real_matches" ]; then
                echo -e "${RED}Secrets detected in commits being pushed:${NC}"
                echo "$real_matches" | head -10
                found_secrets=true
            fi
        fi

        rm -f "$temp_file"
    fi

    if [ "$found_secrets" = true ]; then
        return 1
    fi

    echo -e "${GREEN}✓${NC} No secrets detected in commits"
    return 0
}

# --- Help ---
show_help() {
    echo "Gemini Git Helper v2.4"
    echo ""
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --local, -l         Use local analysis only (no API call)"
    echo "  --pre-commit        Fast secrets-only scan for git hooks (exit 1 if found)"
    echo "  --pre-push RANGE    Scan commits being pushed (for pre-push hook)"
    echo "  --scan-history, -s  Scan commit history for secrets"
    echo "  --commits N         Number of commits to scan (default: 50)"
    echo "  --all-history       Scan entire git history (slower)"
    echo "  --since REF         Scan commits since ref (branch/tag/commit)"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Description:"
    echo "  Analyzes git changes and suggests commit messages using Gemini AI."
    echo "  Falls back to local analysis if API is unavailable."
    echo ""
    echo "  The --scan-history mode checks existing commits for accidentally"
    echo "  committed secrets. Uses gitleaks or trufflehog if available,"
    echo "  otherwise falls back to native grep-based scanning."
    echo ""
    echo "  The --pre-push mode is called by the pre-push git hook to scan"
    echo "  commits about to be pushed. Uses gitleaks for speed."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                    # Full analysis with Gemini API"
    echo "  $(basename "$0") --local            # Quick local analysis without API"
    echo "  $(basename "$0") --scan-history     # Scan last 50 commits for secrets"
    echo "  $(basename "$0") -s --commits 100   # Scan last 100 commits"
    echo "  $(basename "$0") -s --all-history   # Scan entire git history"
    echo "  $(basename "$0") -s --since main    # Scan commits since main branch"
}

# --- Main Execution ---

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local|-l)
                USE_LOCAL_ONLY=true
                shift
                ;;
            --scan-history|-s)
                SCAN_HISTORY=true
                shift
                ;;
            --pre-commit)
                PRE_COMMIT_MODE=true
                USE_LOCAL_ONLY=true
                shift
                ;;
            --pre-push)
                PRE_PUSH_MODE=true
                USE_LOCAL_ONLY=true
                if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
                    PRE_PUSH_RANGE="$2"
                    shift
                fi
                shift
                ;;
            --commits)
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "--commits requires a number"
                    exit 1
                fi
                HISTORY_COMMITS="$2"
                shift 2
                ;;
            --all-history)
                SCAN_ALL_HISTORY=true
                shift
                ;;
            --since)
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "--since requires a ref (branch/tag/commit)"
                    exit 1
                fi
                HISTORY_SINCE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Pre-commit hook mode (fast secrets-only scan)
    if [ "$PRE_COMMIT_MODE" = true ]; then
        check_git_repo
        collect_git_changes
        scan_sensitive_content
        if [ "$SENSITIVE_FOUND" = true ]; then
            exit 1
        fi
        exit 0
    fi

    # Pre-push hook mode (scan commits being pushed)
    if [ "$PRE_PUSH_MODE" = true ]; then
        check_git_repo
        if [ -z "$PRE_PUSH_RANGE" ]; then
            print_error "--pre-push requires a commit range"
            exit 1
        fi
        run_pre_push_scan "$PRE_PUSH_RANGE"
        exit $?
    fi

    # History scanning mode
    if [ "$SCAN_HISTORY" = true ]; then
        print_header "Gemini Git Helper v2.4 (History Scan)"
        check_git_repo
        scan_commit_history
        exit $?
    fi

    # Normal commit helper mode
    if [ "$USE_LOCAL_ONLY" = true ]; then
        print_header "Gemini Git Helper v2.4 (Local Mode)"
    else
        print_header "Gemini Git Helper v2.4"
    fi

    check_git_repo

    if [ "$USE_LOCAL_ONLY" = true ]; then
        # Local mode: quick analysis without API
        collect_git_changes
        scan_sensitive_content
        check_gitignore
        check_dockerignore
        generate_local_commit_suggestion
    else
        # Full mode: use Gemini API
        check_api_keys
        collect_git_changes
        scan_sensitive_content
        check_gitignore
        check_dockerignore

        # Try API, fall back to local if it fails
        if ! call_gemini_api; then
            print_warning "API call failed, using local analysis as fallback"
            generate_local_commit_suggestion
        else
            display_results
        fi
    fi
}

# Run main function
main "$@"
