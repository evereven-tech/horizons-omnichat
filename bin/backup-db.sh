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

# Create backups directory if it doesn't exist
BACKUP_DIR="$PROJECT_ROOT/backups"
mkdir -p "$BACKUP_DIR"

# Generate timestamp for filename
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.sql"

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

echo -e "${GREEN}Starting database backup from $ENV_TYPE environment...${NC}"
echo -e "${YELLOW}Database: $POSTGRES_DB${NC}"
echo -e "${YELLOW}User: $POSTGRES_USER${NC}"

# Execute the backup
echo -e "${GREEN}Creating backup at: $BACKUP_FILE${NC}"
$RUNTIME_CMD exec -e PGPASSWORD="$POSTGRES_PASSWORD" -t "$DB_CONTAINER" \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"

# Verify backup was successful
if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    echo -e "${GREEN}Backup completed successfully: $BACKUP_FILE${NC}"
    echo -e "${GREEN}File size: $(du -h "$BACKUP_FILE" | cut -f1)${NC}"
else
    echo -e "${RED}Error: Backup failed or generated an empty file${NC}"
    rm -f "$BACKUP_FILE"
    exit 1
fi
