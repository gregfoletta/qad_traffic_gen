#!/usr/bin/bash

# Kill off any existing containers
docker container kill $(docker container ls -q)
docker container prune -f

# Spin up the new containers
CONTAINERS=${1:-8}
echo "Spinning up $CONTAINERS containers"
for x in $(seq 1 $CONTAINERS)
do
    echo $x
    #docker run -d --env-file sel_envs --shm-size="2g" selenium/standalone-firefox:4.8.0-20230131	
    docker run -d --env-file sel_envs --shm-size="256m" selenium/standalone-chrome:111.0
done

echo "- Sleeping for 10 seconds"
sleep 10 

DOCKER_IPS=$(docker container inspect $(docker container ls -q) | jq -r '. | map(.NetworkSettings.Networks.bridge.IPAddress) | reverse | join(" ")')

echo "- Docker IPs: $DOCKER_IPS"

#parallel --lb --tmpdir /morespace/tmpdir ./request.pl --uris uris.txt --selenium-ip {$1} --iterations 1000000 --users users.txt ::: $DOCKER_IPS
#parallel --lb --tmpdir /morespace/tmpdir ./request.pl --uris uris.txt --selenium-ip {$1} --iterations 1000000 --users users.txt ::: $DOCKER_IPS
echo -n $DOCKER_IPS | parallel -j0 -d' ' --lb --tmpdir /morespace/tmpdir ./request.pl --uris http_uris.txt --selenium-ip {} --iterations 1000000 --users users.txt --user-index {#} 
# ./request.pl --uris uris.txt --selenium-ips "$DOCKER_IPS" --iterations 1000000 --users users.txt
