#!/usr/bin/bash

docker container kill $(docker container ls -q)

for x in {1..4}
do
    docker run -d --env-file sel_envs --shm-size="2g" selenium/standalone-firefox:4.8.0-20230131	
done

echo "- Sleeping for 10 seconds"
sleep 10 

DOCKER_IPS=$(docker container inspect $(docker container ls -q) | jq -r '. | map(.NetworkSettings.Networks.bridge.IPAddress) | join(",")')

echo "- Docker IPs: $DOCKER_IPS"

parallel --lb -n0 ./request.pl --uris uris.txt --selenium-ips "$DOCKER_IPS" --iterations 100 --users users.txt ::: $(seq 1 6)
