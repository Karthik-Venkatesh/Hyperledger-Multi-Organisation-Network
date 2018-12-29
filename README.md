# Hyperledger Multi Organisation Network

Multi organisation TLS enabled network example implemented using hyperledger fabric and kafka cluster.

## Organisations

1. Org1 (org1.example.com)
2. Org2 (org2.example.com)

## Nodes

### Org1

1. orderer0.example.com
2. orderer1.example.com
3. zookeeper0
4. kafka0
5. kafka1
6. peer0.org1.example.com
7. peer1.org1.example.com
8. couch.peer0.org1.example.com
9. couch.peer1.org1.example.com
10. ca.org1.example.com
11. cli.org1.example.com

### Org2

1. peer0.org2.example.com
2. peer1.org2.example.com
3. couch.peer0.org2.example.com
4. couch.peer1.org2.example.com
5. ca.org2.example.com
6. cli.org2.example.com

## Run Project

```
# Install prereqisites
$ ./prerequisites.sh

# Run network
$ cd network-setup
$ ./deploy.sh

# Run explorer
$ cd explorer
$ ./deploy_explorer.sh dev dev_net

```

## Story

**Org1** have the orderers embeded with kafka cluster, 2 peers embeded with CouchDB,  Certificate Authority and cli. This orgaisation nodes are initially went to running status.
Org1 creates the channelone using it's genesis block.

**Org2** have 2 peers embeded with CouchDB,  Certificate Authority and cli. Org 2 went running state next and joins to **Org1** via channel one.

Then the [merbles chaincode](./chaincode/marbles02/) installed in all the peers and instatiated.

*NOTE:* for execution using shell commands refer **[deploy.sh](./network-setup/deploy.sh)**. And other shell scripts **['network.sh'](./network-setup/network.sh), ['cc-dev.sh'](./network-setup/cc-dev.sh)** shows help by calling `--help`. To clean the docker containers and network execute below commands.

```
# Clean network containers
$ cd network-setup
$ ./clean.sh

# Clean explorer containers
$ cd explorer
$ ./deploy_explorer.sh --down
```
