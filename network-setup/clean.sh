docker stop $(docker ps -aq -f "network=dev_poc")
docker rm $(docker ps -aq -f "network=dev_poc")
docker rmi $(docker images dev-* -q)
docker network rm dev_poc
docker volume prune -f

rm -fr ./tmp
rm -fr ./org-artifacts
rm -fr ./orderer-certs
rm -fr ./*/cards
rm -fr ./*/channel-artifacts
rm -fr ./*/crypto-config