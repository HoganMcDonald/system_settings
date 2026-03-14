---
name: hex
description: >
  Programmatically interact with the Hex data analytics platform (https://hex.tech). Create projects, 
  add python and sql cells to notebooks, write queries against data connections, build 
  stakeholder-facing dashboards.
---

# Hex CLI -- Agent Skill

The `hex` CLI manages Hex projects, cells, runs, data connections, and workspace resources from the command line. Use it to automate Hex workflows, create and modify notebook cells, trigger project runs, and inspect workspace state.

Hex projects include notebook (draft) and app (published) views. Users can create and modify cells in a project, and run a project to generate outputs. Hex uses Python and SQL to execute code and query data connections.

Always pass `--json` when you need to parse output programmatically. JSON mode returns structured data; text mode is for human display only.

## Prerequisites

Before running any command, verify the user is authenticated:

```bash
hex auth status
```

If not logged in, prompt the user to run:

```bash
hex auth login
```

All SQL cells require a data connection (usually a data warehouse or sql database). Users should already have data connections configured. Before starting a complex workflow, query for available data connections and prompt the user to ask which one they would like to use:

```bash
hex connections list
```

If a user is using this skill in a repo that defines a warehouse or database schema, clarify if the data connection matches the desired schema. Use their local schema as context in authoring notebook cells queried against that connection.

## Global Flags

These flags work on every command:

| Flag               | Short | Description                                |
| ------------------ | ----- | ------------------------------------------ |
| `--json`           |       | Output as JSON (for scripting and parsing) |
| `--verbose`        | `-v`  | Show verbose output for debugging          |
| `--quiet`          | `-q`  | Suppress non-essential output              |
| `--no-color`       |       | Disable colored output                     |
| `--api-url <url>`  |       | Override API base URL for this command     |
| `--profile <name>` | `-p`  | Use a specific profile for this command    |

## Profile Management

Profiles store per-environment settings (API URL, output format). The active profile is used by default for all commands.

```bash
# List all profiles
hex profile list

# Add a profile
hex profile add <name> [--api-url <url>] [--output-format <text|json>]

# Switch active profile
hex profile use <name>

# Remove a profile
hex profile remove <name>

# Show current active profile
hex profile current
```

## Command Reference

### auth

```bash
hex auth login    # Log in via browser-based OAuth device flow
hex auth logout   # Log out and clear stored credentials
hex auth status   # Show current authentication status
```

### projects

```bash
# List projects (default limit 25)
hex projects list [-n <limit>] [--status <published|draft|archived>]

# Get project details
hex projects get <project_id>

# Open project in browser
hex projects open <project_id>
```

### cells

```bash
# List cells in a project (default limit 25)
hex cells list <project_id> [-n <limit>]

# Get a single cell
hex cells get <cell_id>

# Create a cell
hex cells create <project_id> \
  -t <code|sql> \
  -s <source> \
  [-l <label>] \
  [--data-connection-id <uuid>] \
  [--output-dataframe <name>] \
  [--after-cell-id <uuid>] \
  [--parent-cell-id <uuid>] \
  [--child-position <first|last>]

# Update a cell
hex cells update <cell_id> \
  [-t <code|sql>] \
  [-s <source>] \
  [--data-connection-id <uuid>] \
  [--output-dataframe <name>]

# Delete a cell
hex cells delete <cell_id>

# Run a cell and its dependencies
hex cells run <cell_id> [--dry-run]
```

### connections

```bash
# List all data connections
hex connections list [-t <connection_type>]

# Get connection details
hex connections get <connection_id>
```

### collections

```bash
# List all collections
hex collections list

# Get collection details
hex collections get <collection_id>
```

### groups

IMPORTANT: stop and ask permission from a user before making any changes to groups.

```bash
# List all groups
hex groups list

# Get group details
hex groups get <group_id>

# Create a group
hex groups create <name>

# Delete a group
hex groups delete <group_id>
```

### users

```bash
# List users (default limit 50)
hex users list [-n <limit>]

# Get user details (by ID or email)
hex users get <user_id_or_email>
```

### config

```bash
# Show all configuration
hex config list

# Get a config value
hex config get <key>

# Set a config value
hex config set <key> <value>

# Show config file path
hex config path
```

Config keys: `api_url`, `output_format`, `active_profile`, `update_check`, `logging_enabled`.

### logs

```bash
# Print log contents
hex logs [-n <lines>]

# Follow logs (like tail -f)
hex logs -f

# Print log file path
hex logs --path
```

## Workflow Examples

IMPORTANT: always open the project in a users browser when making changes to cells:

```bash
# opens project in default browser. Also spawns a kernal for executing cells in, which is necessary for running a cell
hex projects open "$PROJECT_ID"
```

### Create a project and add cells

```bash
# List projects to find the target
PROJECT_ID=$(hex projects list --json | jq -r '.projects[0].id')

# Create a Python code cell
hex cells create "$PROJECT_ID" -t code -s "import pandas as pd
df = pd.read_csv('data.csv')
df.head()"

# Create a SQL cell after the first one
FIRST_CELL=$(hex cells list "$PROJECT_ID" --json | jq -r '.cells[0].id')
hex cells create "$PROJECT_ID" -t sql -s "SELECT * FROM my_table LIMIT 10" \
  --after-cell-id "$FIRST_CELL" --data-connection-id "$DATA_CONNECTION_ID"

# Verify cells were created
hex cells list "$PROJECT_ID"
```

### Discover data connections and create SQL cells

```bash
# List available connections
hex connections list --json

# Ask the user which connection to use, then create a SQL cell with it
CONNECTION_ID="<selected-connection-id>"
hex cells create "$PROJECT_ID" -t sql \
  -s "SELECT count(*) FROM users" \
  --data-connection-id "$CONNECTION_ID" \
  --output-dataframe "user_count"

# Run the cell
CELL_ID=$(hex cells list "$PROJECT_ID" --json | jq -r '.cells[-1].id')
hex cells run "$CELL_ID"
```

### Open, update, and run

```bash
# Get project details
hex projects get "$PROJECT_ID" --json

# Open in browser for the user to review
hex projects open "$PROJECT_ID"

# List cells and update one
CELLS=$(hex cells list "$PROJECT_ID" --json)
CELL_ID=$(echo "$CELLS" | jq -r '.cells[0].id')
hex cells update "$CELL_ID" -t code -s "print('updated code')"

# Run the updated cell
hex cells run "$CELL_ID"
```

### Run with parameters and monitor

```bash
# Trigger a run with input parameters
hex run "$PROJECT_ID" \
  -i start_date=2024-01-01 \
  -i end_date=2024-12-31 \
  -i threshold=0.95 \
  --timeout 30m

# Or run async and monitor separately
hex run "$PROJECT_ID" -i region=us-east-1 --no-wait --json
# Returns: {"run_id": "...", "project_id": "...", "status": "PENDING", "run_url": "..."}

RUN_ID="<run_id from above>"
hex runs status "$PROJECT_ID" "$RUN_ID" --watch
```

### Workspace management

```bash
# List users and groups
hex users list --json
hex groups list --json

# Create a new group
hex groups create "Data Engineering"
```

### Troubleshooting a failed run

```bash
# Check run status
hex runs status "$PROJECT_ID" "$RUN_ID" --json
# Look at the "status" field: COMPLETED, ERRORED, KILLED, UNABLE_TO_ALLOCATE_KERNEL

# View CLI logs for debugging
hex logs -n 50

# If a run is stuck, cancel and retry
hex runs cancel "$PROJECT_ID" "$RUN_ID"
hex run "$PROJECT_ID" --no-cache
```
