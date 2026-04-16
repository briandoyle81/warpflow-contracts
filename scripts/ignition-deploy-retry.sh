#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./ignition-deploy-retry.sh --network <network-name> --deploy-script <path/to/OnchainModule.ts>

Options:
  --skip-verify        Do not pass `--verify` to hardhat ignition deploy
  --no-auto-confirm   Do not auto-answer "y" to any deploy confirmation prompts
  --sleep-seconds <n> Sleep seconds between retries on transient errors (see retry conditions below)

Environment variables:
  LOG_FILE            Log file to write (default: ignition_deploy_retry.log)
  SLEEP_SECONDS      Sleep seconds between retries (default: 5)
EOF
}

NETWORK=""
DEPLOY_SCRIPT=""
VERIFY=1
AUTO_CONFIRM=1
SLEEP_SECONDS_DEFAULT="5"

LOG_FILE="${LOG_FILE:-ignition_deploy_retry.log}"
SLEEP_SECONDS="${SLEEP_SECONDS:-$SLEEP_SECONDS_DEFAULT}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --network)
      NETWORK="${2:-}"
      shift 2
      ;;
    --deploy-script)
      DEPLOY_SCRIPT="${2:-}"
      shift 2
      ;;
    --skip-verify)
      VERIFY=0
      shift 1
      ;;
    --no-auto-confirm)
      AUTO_CONFIRM=0
      shift 1
      ;;
    --sleep-seconds)
      SLEEP_SECONDS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$NETWORK" || -z "$DEPLOY_SCRIPT" ]]; then
  usage >&2
  exit 2
fi

CMD=(npx hardhat ignition deploy "$DEPLOY_SCRIPT" --network "$NETWORK")
if [[ "$VERIFY" -eq 1 ]]; then
  CMD+=(--verify)
fi

while true; do
  : > "$LOG_FILE"
  echo "--- retry $(date) ---"

  # Run and stream output to log; capture the deploy command exit code from bash's PIPESTATUS.
  set +e
  if [[ "$AUTO_CONFIRM" -eq 1 ]]; then
    # Hardhat Ignition may ask for an interactive confirmation (e.g. "Confirm deploy to network ... (y/N)").
    # Feed "y" continuously so retries never require human interaction.
    "${CMD[@]}" < <(yes) 2>&1 | tee "$LOG_FILE"
  else
    "${CMD[@]}" 2>&1 | tee "$LOG_FILE"
  fi
  ec="${PIPESTATUS[0]}"
  set -e

  if [[ "$ec" -eq 0 ]]; then
    echo "SUCCESS"
    exit 0
  fi

  # Retry on transient errors: nonce mismatch, Ignition rerun hint, underpriced gas, or IGN411
  # without the "use a block explorer" hint (that case needs track-tx or ignition wipe, not a blind retry).
  python3 -c '
import pathlib, sys
p = pathlib.Path("'"$LOG_FILE"'")
s = p.read_text(errors="ignore")
explorer_hint = "Please use a block explorer" in s
retry_ign411 = "IGN411" in s and not explorer_hint
retry = (
    "The next nonce" in s
    or "Please try rerunning Hardhat Ignition." in s
    or retry_ign411
    or "transaction underpriced" in s
)
sys.exit(0 if retry else 1)
'
  if [[ $? -eq 0 ]]; then
    echo "Retrying due to transient deploy error..."
    sleep "$SLEEP_SECONDS"
    continue
  fi

  echo "Stopping due to non-retryable error (exit code: $ec)"
  exit "$ec"
done

