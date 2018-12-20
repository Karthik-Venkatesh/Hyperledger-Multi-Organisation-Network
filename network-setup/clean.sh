docker stop $(docker ps -aq -f "network=dev_poc")
docker rm $(docker ps -aq -f "network=dev_poc")
docker rmi $(docker images scm-* -q)
docker network rm dev_poc
docker volume prune -f

rm -fr ./tmp
rm -fr ./org-artifacts
rm -fr ./orderer-certs
rm -fr ./*/cards
rm -fr ./*/channel-artifacts
rm -fr ./*/crypto-config
find . -print | grep -P "\w*\.\w*\.connection\.json(\.bak)?" | xargs -d"\n" rm -rf
find . -print | grep -P "\w*\/docker-config\/docker-compose-(base|ca)\.yml?" | xargs -d"\n" rm -rf