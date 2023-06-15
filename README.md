# Database Backup Generator
This script generates backups of all databases in a PostgreSQL container and saves them in a folder in the host machine.

# Requirements
- Docker [*](https://docs.docker.com/engine/install/)
- A Docker container with a PostgreSQL image [*](https://hub.docker.com/_/postgres)
- Docker with sudo permissions [*](https://docs.docker.com/engine/install/linux-postinstall/)

# How to use
## Setup
1. Clone this repository
2. Copy the file `database_backup_generator.sh` to your host machine
3. Give execution permissions to the file
```bash
chmod +x database_backup_generator.sh
```

## Default configuration
4. Run the script
```bash
./database_backup_generator.sh
```

## Custom configuration
4. You can run the script with the following parameters:
- `--container-name <container_name>`: The name of the container with the PostgreSQL image
- `--username <username>`: The username of the PostgreSQL user
- `--backup-directory <path>`: The path of the folder where the backups will be saved
- `--default-dbs`: If this flag is set, the script will generate backups of the default databases (postgres, template0, template1)

Example:
```bash
./database_backup_generator.sh --container-name my_postgres_container --username my_user --backup-directory /tmp/backups --default-dbs
```

## Crontab
4. You can add the script to your crontab file to run it automatically.
```bash
crontab -e
```
5. For example, if you want to run the script every Sunday at 00:00, you can add the following line to your crontab file (replace the paths with your own):
```bash
0 0 * * 0 /database_backup_generator.sh >> /tmp/backups/database_backup_generator.log 2>&1
```
(The script will generate a log file in the path `/tmp/backups/database_backup_generator.log`)