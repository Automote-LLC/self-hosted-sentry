echo "${_group}Creating initial user (if configured) ..."

# Check if user creation is requested via environment variables
if [[ -n "${SENTRY_INITIAL_USER_EMAIL:-}" ]] && [[ -n "${SENTRY_INITIAL_USER_PASSWORD:-}" ]]; then
  echo "Initial user email and password provided, creating superuser ..."
  
  # Wait for web service to be ready
  start_service_and_wait_ready web
  
  # Create the user with the provided credentials
  # Using --force-update to update if user already exists
  if $dcr web createuser \
    --force-update \
    --superuser \
    --email "$SENTRY_INITIAL_USER_EMAIL" \
    --password "$SENTRY_INITIAL_USER_PASSWORD" \
    --no-input; then
    echo "Successfully created/updated superuser: $SENTRY_INITIAL_USER_EMAIL"
  else
    echo "Warning: Failed to create initial user. You may need to create one manually."
    echo "Run: $dc_base run --rm web createuser"
  fi
else
  echo "SENTRY_INITIAL_USER_EMAIL and SENTRY_INITIAL_USER_PASSWORD not set, skipping automatic user creation."
  echo "To create a user manually, run: $dc_base run --rm web createuser"
fi

echo "${_endgroup}"
