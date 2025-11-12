# Grafana Dashboards

## Directory Structure

Dashboards are automatically created in Grafana based on their location in this folder:

```
dashboards/
  dashboard.json              → Created at root level (no folder)
  team-name/
    dashboard.json            → Created in team-name's Grafana folder
```

## Adding Dashboards

**Platform-wide dashboards** (landing pages, global overviews):
- Place JSON files at the root level: `dashboards/your-dashboard.json`
- These appear at the top level in Grafana with no folder assignment

**Team-specific dashboards**:
- Place JSON files in team subfolders: `dashboards/{team-name}/your-dashboard.json`
- Team name must match a tenant name from `environment-configurations.tf`
- These are automatically placed in the team's Grafana folder with appropriate permissions