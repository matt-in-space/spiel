# Archived workflows

Workflows kept for reference only. GitHub Actions only runs files in
`.github/workflows/`, so nothing here executes.

- `fly-deploy.yml` — continuous deployment to Fly.io after CI passed on `main`.
  Archived because the app is no longer deployed. To restore, move it back to
  `.github/workflows/` and set the `FLY_API_TOKEN` repository secret.
