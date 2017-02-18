#!/bin/bash

# Script variables
backup_directory='/Users/willjackson/docker-presentation/scripts/pantheon-backup/import'
volume_directory='/Users/willjackson/docker-presentation/scripts/docroot'
terminus='/Users/willjackson/vendor/bin/terminus'
d7_base_container='/Users/willjackson/docker-presentation/scripts/d7_pantheon_base'
dockerhub_user='willjackson'

# Functions
function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

site_list="$($terminus site:list --field=name | awk '{ print $1 }' | tail -n +1)"

## Create array from terminus site listing
declare -a sites=(${site_list})

## User input to select site
PS3='Please enter your choice: '
select site in "${sites[@]}"
do
    case $site in
        "$site")
            site=$REPLY
            break
            ;;
        "quit")
            break
            ;;
        *) echo 'invalid option, type "quit" to quit';;
    esac
done

env_list="$($terminus env:list $site --field=id | awk '{ print $1 }')"

## Create array from terminus site listing
declare -a environments=(${env_list})

## User input to select environment
PS3='Please enter your choice: '
select env in "${environments[@]}"
do
    case $env in
        "$env")
            env=$REPLY
            break
            ;;
        "quit")
            break
            ;;
        *) echo 'invalid option, type "quit" to quit';;
    esac
done

# Create backup directory for site assets
mkdir -p $backup_directory/$site
mkdir -p $backup_directory/$site


# Backup code.  
# Note: This is a bit cleaner than executing git command inside the container, once built.

echo "Downloading codebase backup."
codeBackup="$($terminus backup:get $site.$env --to=$backup_directory/$site/backup.code.tar.gz --element=code 2>&1 >/dev/null)"

if [[ $codeBackup == *"No backups available."* ]]
then
  echo "No code backup available. Creating one now.";
  $terminus backup:create $site.$env --element=code;
  $terminus backup:get $site.$env --to=$backup_directory/$site/backup.code.tar.gz --element=code 
fi

# Backup database.

echo "Downloading database backup."
databaseBackup="$($terminus backup:get $site.$env --to=$backup_directory/$site/backup.db.sql.gz --element=database 2>&1 >/dev/null)"

if [[ $databaseBackup == *"No backups available."* ]]
then
  echo "No database backup available. Creating one now.";
  $terminus backup:create $site.$env --element=database;
  $terminus backup:get $site.$env --to=$backup_directory/$site/backup.db.sql.gz --element=database 
fi

# Backup filesystem
# Note: Need to add switch to allow remote filesystem rewrites (stage_file_proxy module)

echo "Downloading filesystem backup."
filesBackup="$($terminus backup:get $site.$env --to=$backup_directory/$site/backup.files.tar.gz --element=files 2>&1 >/dev/null)"

if [[ $filesBackup == *"No backups available."* ]]
then
  echo "No filesystem backups available. Creating one now.";
  $terminus backup:create $site.$env --element=files;
  $terminus backup:get $site.$env --to=$backup_directory/$site/backup.files.tar.gz --element=files 
fi


# Detect site framework
siteFramework="$($terminus site:info $site --field=framework)"

# Determine next available port for docker port 80
for image in $(docker ps -aq ); do
    port=$(docker inspect $image | grep HostPort | awk '!a[$0]++')
    port="${port//[!0-9]/}"
    docker_port_used+=("$port")
done

for docker_port in $(seq 8001 8999); do
  docker_port_available+=("$docker_port")
  
  if [ $(contains "${docker_port_used[@]}" "$docker_port") == "n" ]; then
    next_port=$docker_port;
    break
	fi

done


if [[ $siteFramework == *"drupal"* ]]
then
  # echo $siteFramework
  echo "Drupal project.";
  cp -r $d7_base_container $backup_directory/$site/image
  cp $backup_directory/$site/backup.files.tar.gz $backup_directory/$site/image/assets
  cp $backup_directory/$site/backup.db.sql.gz $backup_directory/$site/image/assets
  gunzip $backup_directory/$site/image/assets/backup.db.sql.gz
  cp $backup_directory/$site/backup.code.tar.gz $backup_directory/$site/image/assets
  docker build -t $dockerhub_user/$site $backup_directory/$site/image
  docker run -td --name=$site -p $next_port:80 -v $volume_directory/$site:/var/www/html $dockerhub_user/$site
fi

if [[ $siteFramework == *"wordpress"* ]]
then
	# echo $siteFramework
	echo "Wordpress site."
fi
