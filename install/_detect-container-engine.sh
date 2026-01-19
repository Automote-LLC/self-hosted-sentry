echo "${_group}Detecting container engine ..."

# Check if we're in Railway environment
# Railway sets RAILWAY_ENVIRONMENT, RAILWAY_SERVICE_NAME, or RAILWAY_PROJECT_ID
if [[ -n "${RAILWAY_ENVIRONMENT:-}" ]] || [[ -n "${RAILWAY_SERVICE_NAME:-}" ]] || [[ -n "${RAILWAY_PROJECT_ID:-}" ]]; then
  # In Railway, Docker is available but might not be in PATH during install phase
  # Railway uses docker compose internally, so we assume docker is available
  export CONTAINER_ENGINE="docker"
  echo "Detected Railway environment, assuming docker"
  echo "${_endgroup}"
  return 0 2>/dev/null || exit 0
fi

if [[ "${CONTAINER_ENGINE_PODMAN:-0}" -eq 1 ]] && command -v podman &>/dev/null; then
  export CONTAINER_ENGINE="podman"
elif command -v docker &>/dev/null; then
  export CONTAINER_ENGINE="docker"
else
  echo "FAIL: Neither podman nor docker is installed on the system."
  exit 1
fi
echo "Detected container engine: $CONTAINER_ENGINE"
echo "${_endgroup}"
