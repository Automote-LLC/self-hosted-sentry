# Deploying Self-Hosted Sentry on Railway.app

This guide will walk you through deploying Self-Hosted Sentry on Railway.app, a cloud platform that simplifies containerized application deployment.

## Overview

Railway.app is a platform that allows you to deploy Docker Compose applications easily. This deployment setup has been modified to:

- Automatically detect Railway environment
- Create initial admin user via environment variables (no terminal access needed)
- Auto-start all services after installation
- Handle Docker detection gracefully in Railway's environment

## Prerequisites

- A Railway.app account ([sign up here](https://railway.app))
- A GitHub repository with this self-hosted Sentry codebase (or use Railway's GitHub integration)
- Basic understanding of environment variables

## Step-by-Step Deployment

### 1. Create a New Railway Project

1. Log in to [Railway.app](https://railway.app)
2. Click "New Project"
3. Select "Deploy from GitHub repo" (recommended) or "Empty Project"
4. If using GitHub, select your repository containing this self-hosted Sentry codebase

### 2. Configure Railway Service

Railway will automatically detect your `docker-compose.yml` file. You need to configure the service to run the installation script.

#### Option A: Using railway.toml (Recommended)

A `railway.toml` file is already included in the repository. It configures Railway to:
1. Run the installation script first (`./install.sh`)
2. Then start all services with `docker compose up --wait`

The file is already configured correctly. Railway will automatically use it.

#### Option B: Using Railway's Start Command

If you prefer to set it manually in Railway's dashboard:

1. In your Railway project, go to the service settings
2. Set the **Start Command** to:
   ```bash
   bash -c './install.sh --skip-user-creation --skip-commit-check && docker compose up --wait'
   ```

**Note**: The `railway.toml` file is the recommended approach as it's already configured and version-controlled.

### 3. Set Required Environment Variables

In Railway, go to your service's **Variables** tab and add the following:

#### Required for User Creation

- **`SENTRY_INITIAL_USER_EMAIL`**: The email address for your admin user (e.g., `admin@example.com`)
- **`SENTRY_INITIAL_USER_PASSWORD`**: The password for your admin user (use a strong password)

#### Optional but Recommended

- **`SENTRY_SYSTEM_SECRET_KEY`**: A secret key for cryptographic operations. If not set, one will be generated automatically.
  - Generate one with: `openssl rand -base64 32`
- **`SENTRY_MAIL_HOST`**: Your SMTP host for email notifications (e.g., `smtp.gmail.com`)
- **`SENTRY_EVENT_RETENTION_DAYS`**: How long to retain events (default: 90 days)
- **`COMPOSE_PROFILES`**: Set to `feature-complete` for all features, or `errors-only` for minimal setup
  - Default: `errors-only` (minimal)
  - Recommended: `feature-complete` (full features)

#### Installation Flags (Optional)

- **`SKIP_USER_CREATION`**: Set to `1` to skip user creation (already handled by start command)
- **`SKIP_COMMIT_CHECK`**: Set to `1` to skip commit check (recommended for Railway)
- **`SKIP_SSE42_REQUIREMENTS`**: Set to `1` to skip SSE4.2 requirements check (if needed)
- **`REPORT_SELF_HOSTED_ISSUES`**: Set to `0` to disable reporting to Sentry (privacy)

### 4. Configure Ports

Railway automatically exposes ports, but you should verify:

1. Go to your service settings
2. Ensure port **80** is exposed (or configure Railway to use your custom port)
3. Railway will provide a public URL automatically

### 5. Deploy

1. Railway will automatically start building and deploying when you push to your repository
2. Or click "Deploy" in the Railway dashboard
3. Monitor the deployment logs in Railway's dashboard

### 6. Access Your Sentry Instance

1. Once deployment completes, Railway will provide a public URL (e.g., `https://your-project.railway.app`)
2. Open the URL in your browser
3. Log in with the credentials you set in `SENTRY_INITIAL_USER_EMAIL` and `SENTRY_INITIAL_USER_PASSWORD`

## Environment Variables Reference

### User Creation

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SENTRY_INITIAL_USER_EMAIL` | Yes | Admin user email | `admin@example.com` |
| `SENTRY_INITIAL_USER_PASSWORD` | Yes | Admin user password | `SecurePassword123!` |

### Sentry Configuration

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `SENTRY_SYSTEM_SECRET_KEY` | No | Secret key for crypto operations | Auto-generated |
| `SENTRY_MAIL_HOST` | No | SMTP host for emails | - |
| `SENTRY_EVENT_RETENTION_DAYS` | No | Days to retain events | `90` |
| `COMPOSE_PROFILES` | No | Feature set: `feature-complete` or `errors-only` | `errors-only` |

### Installation Control

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `SKIP_USER_CREATION` | No | Skip user creation prompt | `0` |
| `SKIP_COMMIT_CHECK` | No | Skip latest commit check | `0` |
| `SKIP_SSE42_REQUIREMENTS` | No | Skip SSE4.2 requirements | `0` |
| `REPORT_SELF_HOSTED_ISSUES` | No | Report issues to Sentry | `0` |

## How It Works

### Railway Environment Detection

The installation script automatically detects Railway environment by checking for Railway-specific environment variables:
- `RAILWAY_ENVIRONMENT`
- `RAILWAY_SERVICE_NAME`
- `RAILWAY_PROJECT_ID`

When detected, the script:
1. Assumes Docker is available (even if not in PATH during install)
2. Skips manual Docker detection
3. Automatically starts services after installation
4. Creates initial user if credentials are provided

### Automatic User Creation

If `SENTRY_INITIAL_USER_EMAIL` and `SENTRY_INITIAL_USER_PASSWORD` are set:
1. After database migrations complete
2. The script automatically creates a superuser with those credentials
3. You can log in immediately after deployment

### Service Startup

In Railway environment, services are automatically started with `docker compose up --wait` after installation completes.

## Troubleshooting

### Issue: "Neither podman nor docker is installed" or crashes at "Detecting Docker platform"

**Solution**: This should be automatically handled by Railway detection. If you still see this:
- Ensure Railway environment variables are set (they should be automatic)
- Check that you're using the latest version of the installation scripts
- Verify that `RAILWAY_ENVIRONMENT`, `RAILWAY_SERVICE_NAME`, or `RAILWAY_PROJECT_ID` is set in your Railway service
- If the issue persists, you can manually set `DOCKER_PLATFORM=linux/amd64` as an environment variable in Railway

### Issue: User creation fails

**Possible causes**:
- Email or password not set in environment variables
- Database migrations haven't completed yet
- User already exists (script will update existing user)

**Solution**:
- Verify `SENTRY_INITIAL_USER_EMAIL` and `SENTRY_INITIAL_USER_PASSWORD` are set
- Check deployment logs for migration status
- Wait for all services to be healthy before accessing

### Issue: Services not starting

**Solution**:
- Check Railway deployment logs
- Verify Docker Compose is working: Railway should handle this automatically
- Ensure sufficient resources are allocated to your Railway service

### Issue: Cannot access Sentry UI

**Possible causes**:
- Services are still starting (check logs)
- Port not exposed correctly
- Health checks failing

**Solution**:
- Wait 2-3 minutes after deployment for all services to start
- Check Railway service logs for errors
- Verify the public URL is correct

### Issue: Database connection errors

**Solution**:
- Ensure PostgreSQL service is healthy
- Check that database migrations completed successfully
- Review logs for specific database errors

## Railway-Specific Considerations

### Resource Requirements

Self-Hosted Sentry requires significant resources:
- **Memory**: Minimum 4GB RAM recommended (8GB+ for feature-complete)
- **CPU**: 2+ cores recommended
- **Storage**: 20GB+ for data volumes

Railway's free tier may not be sufficient. Consider upgrading to a paid plan.

### Persistent Storage

Railway handles Docker volumes automatically. Data persists across deployments, but:
- Volumes are tied to your Railway service
- If you delete the service, data is lost (unless backed up)
- Consider setting up regular backups

### Scaling

Railway can scale your service, but Sentry's architecture:
- Uses many interdependent services
- Requires careful scaling configuration
- May need manual service scaling for different components

### Cost Considerations

Railway pricing is based on usage:
- Free tier: Limited resources
- Paid plans: Pay for what you use
- Self-hosted Sentry can be resource-intensive

Monitor your Railway usage and costs.

## Updating Your Deployment

To update your Sentry instance:

1. Pull the latest changes from the repository
2. Railway will automatically rebuild and redeploy
3. The installation script handles migrations automatically
4. Your data and configuration persist

## Security Best Practices

1. **Strong Passwords**: Use a strong password for `SENTRY_INITIAL_USER_PASSWORD`
2. **Secret Key**: Set `SENTRY_SYSTEM_SECRET_KEY` to a secure random value
3. **HTTPS**: Railway provides HTTPS automatically, but verify it's enabled
4. **Environment Variables**: Never commit sensitive values to your repository
5. **Regular Updates**: Keep your Sentry instance updated for security patches

## Getting Help

- **Railway Documentation**: [docs.railway.app](https://docs.railway.app)
- **Sentry Self-Hosted Docs**: [develop.sentry.dev/self-hosted](https://develop.sentry.dev/self-hosted/)
- **GitHub Issues**: Report issues in the self-hosted Sentry repository

## Additional Notes

- Railway automatically provides a public URL with HTTPS
- You can configure a custom domain in Railway settings
- Railway handles Docker Compose automatically
- All services run in a single Railway service (monolithic deployment)
- For production use, consider dedicated infrastructure for better performance

## railway.toml Configuration

The `railway.toml` file is already included in the repository with the correct configuration:

```toml
[build]
builder = "dockerfile"

[deploy]
startCommand = "bash -c './install.sh --skip-user-creation --skip-commit-check && docker compose up --wait'"
```

This ensures that:
1. The installation script runs first to set up everything
2. Then `docker compose up --wait` starts all services and waits for them to be healthy

**Important**: Sensitive variables like `SENTRY_INITIAL_USER_EMAIL` and `SENTRY_INITIAL_USER_PASSWORD` should be set in Railway's dashboard (Variables tab), not in the `railway.toml` file.
