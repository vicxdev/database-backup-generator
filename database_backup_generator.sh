#!/bin/bash

echo "-------------- BACKUP SCRIPT START --------------------"

# Function to print the current date and time
print_datetime() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to exit the script when an error occurs
exit_error_script() {
    print_datetime "$1"
    echo "--------------- BACKUP SCRIPT END ---------------------"
    exit 1
}

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    exit_error_script "ERROR: Docker is not installed. Please install Docker before running this script."
fi

# Check if running interactively
if [[ "$*" == *"-t"* ]]; then
    echo "Running in interactive mode. Leave the inputs blank to use defaults."
    read -rp "Enter the container name (default: postgres): " container_name
    container_name=${container_name:-"postgres"}

    read -rp "Enter the database username (default: postgres): " username
    username=${username:-"postgres"}

    read -rp "Enter the backup directory (default: /tmp/backups): " backup_directory
    backup_directory=${backup_directory:-"/tmp/backups"}

    read -rp "Backup default PostgreSQL databases? (y/N): " backup_default_databases
    backup_default_databases=${backup_default_databases:-"n"}

    case $backup_default_databases in
    [yY]|[yY][eE][sS])
        backup_default_databases="y"
        ;;
    [nN]|[nN][oO])
        backup_default_databases="n"
        ;;
    *)
        exit_error_script "ERROR: Invalid input. Please enter y or n."
        ;;
    esac
else
    # Default parameter values
    container_name="postgres"
    username="postgres"
    backup_directory="/tmp/backups"
    backup_default_databases="n"

    # Process command-line options using getopt
    while (( "$#" )); do
        case "$1" in
            --container-name)
                container_name="$2"
                shift 2
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --backup-directory)
                backup_directory="$2"
                shift 2
                ;;
            --default-dbs)
                backup_default_databases="y"
                shift
                ;;
            *)
                echo "Invalid option: $1" >&2
                exit 1
                ;;
        esac
    done
fi

# Check if the selected container exists
if ! docker container inspect "$container_name" >/dev/null 2>&1; then
    exit_error_script "ERROR: Container $container_name does not exist."
fi

# Check if the selected container has PostgreSQL installed
if ! docker exec "$container_name" psql --version >/dev/null 2>&1; then
    exit_error_script "ERROR: PostgreSQL is not installed in the $container_name container."
fi

# Create the backup directory if it doesn't exist
if [ ! -d "$backup_directory" ]; then
    mkdir -p "$backup_directory"
    echo "Created backup directory $backup_directory"
fi

# Get the list of databases
print_datetime "Getting all databases..."
databases=$(docker exec -u postgres "$container_name" psql -U "$username" -lqt | cut -d \| -f 1)

if [ -z "$databases" ]; then
    exit_error_script "ERROR: No databases found!"
fi

# If backup_default_databases is set to n, skip the default databases and backup only the user created ones
if [[ "$backup_default_databases" == "n" ]]; then
    # Loop through the databases and filter out the excluded names
    exclude_databases=("postgres" "template0" "template1")
    filtered_databases=""
    for database in $databases; do
        # Check if the current database is in the list of excluded names
        if [[ ! " ${exclude_databases[@]} " =~ " ${database} " ]]; then
            # Append the database name to the filtered list
            filtered_databases+=" $database"
        fi
    done
# If backup_default_databases is set to y, backup all databases (including the default ones)
else
    filtered_databases="$databases"
fi

# Loop through the databases and create backups
print_datetime "Starting databases backups..."
for database in $filtered_databases; do
    print_datetime "Backing up $database..."

    # Get the current date and time in YYYY-MM-DD_HH-MM-SS format
    current_date=$(date +'%Y-%m-%d_%H-%M-%S')

    # Define the backup file name and path
    backup_file="${backup_directory}/dump_${database}_${current_date}.sql"
    print_datetime "Saving database backup at $backup_file"

    # Run the database backup command
    if docker exec -u postgres "$container_name" pg_dump -U "$username" -d "$database" > "$backup_file"; then
        print_datetime "$database database backup completed!"
    else
        exit_error_script "ERROR: Failed to backup $database database."
    fi
done

echo "--------------- BACKUP SCRIPT END ---------------------"
