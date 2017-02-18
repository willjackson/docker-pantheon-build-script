#!/bin/bash

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

echo $next_port


