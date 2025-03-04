#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine script and project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Detect container runtime (podman or docker)
CONTAINER_RUNTIME=$(which podman 2>/dev/null || which docker 2>/dev/null)
if [ -z "$CONTAINER_RUNTIME" ]; then
    echo -e "${RED}Error: No container runtime found. Please install podman or docker.${NC}"
    exit 1
fi
RUNTIME_CMD=$(basename "$CONTAINER_RUNTIME")
echo -e "${GREEN}Using container runtime: $RUNTIME_CMD${NC}"

# PostgreSQL container name
DB_CONTAINER="open-webui-db"

# Function to check if container is running
check_container() {
    local env_dir=$1
    local env_file="$PROJECT_ROOT/$env_dir/.env"
    
    if [ -f "$env_file" ]; then
        echo -e "${YELLOW}Loading configuration from $env_file${NC}"
        source "$env_file"
        
        if $RUNTIME_CMD ps | grep -q "$DB_CONTAINER"; then
            echo -e "${GREEN}Found PostgreSQL container in $env_dir environment${NC}"
            return 0
        fi
    fi
    
    return 1
}

# Try to find the running container in local or hybrid environment
if check_container "local"; then
    ENV_TYPE="local"
elif check_container "hybrid"; then
    ENV_TYPE="hybrid"
else
    echo -e "${RED}Error: PostgreSQL container '$DB_CONTAINER' is not running in any environment${NC}"
    echo -e "${YELLOW}Make sure either local or hybrid environment is up and running${NC}"
    exit 1
fi

# Check if backup file was provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: You must provide the path to a SQL backup file${NC}"
    echo -e "${YELLOW}Usage: $0 path/to/backup.sql${NC}"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file does not exist: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Found database in $ENV_TYPE environment${NC}"
echo -e "${YELLOW}Database: $POSTGRES_DB${NC}"
echo -e "${YELLOW}User: $POSTGRES_USER${NC}"
echo -e "${YELLOW}Restore file: $BACKUP_FILE${NC}"

# Confirm before proceeding
echo -e "${RED}WARNING! This operation will overwrite the current database.${NC}"
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo -e "${GREEN}Restoring database from $BACKUP_FILE...${NC}"

# Terminate existing connections
echo -e "${YELLOW}Terminating existing database connections...${NC}"
$RUNTIME_CMD exec -e PGPASSWORD="$POSTGRES_PASSWORD" -t "$DB_CONTAINER" \
  psql -U "$POSTGRES_USER" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DB' AND pid <> pg_backend_pid();"

# Drop and recreate database
echo -e "${YELLOW}Dropping and recreating database...${NC}"
$RUNTIME_CMD exec -e PGPASSWORD="$POSTGRES_PASSWORD" -t "$DB_CONTAINER" \
  psql -U "$POSTGRES_USER" -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"

$RUNTIME_CMD exec -e PGPASSWORD="$POSTGRES_PASSWORD" -t "$DB_CONTAINER" \
  psql -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"

# Restore from backup file
echo -e "${YELLOW}Importing data from backup...${NC}"
cat "$BACKUP_FILE" | $RUNTIME_CMD exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

# Verify restoration was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Database restoration completed successfully${NC}"
else
    echo -e "${RED}Error: Database restoration failed${NC}"
    exit 1
fi
