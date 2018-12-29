
set -x

#*****************************************Org1*******************************************#

set -e
# Constructing org1.example.com infrastructure
./network.sh --sourcePath ./org1.example.com --mode generateCrypto
./network.sh --sourcePath ./org1.example.com --mode generateArtifacts --network new --mspId Org1MSP --channelName channelone
./network.sh --sourcePath ./org1.example.com --mode createDockerComposeCA --domain example.com --org org1
./network.sh --sourcePath ./org1.example.com --mode copyOrdererCerts --domain example.com
./network.sh --sourcePath ./org1.example.com --mode up

sleep 30

set +e

#*****************************************Org2*******************************************#

# Creating channelone
./network.sh --sourcePath ./org1.example.com --mode createChannel --cli cli.org1.example.com --channelName channelone --peer peer0.org1.example.com:7051 --orderer orderer0.example.com:7050
./network.sh --mode joinChannel --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone
./network.sh --mode joinChannel --cli cli.org1.example.com --peer peer1.org1.example.com:7051 --channelName channelone
./network.sh --sourcePath ./org1.example.com --mode updateAnchorPeer --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --mspId Org1MSP --orderer orderer0.example.com:7050

# Constructing org2.example.com infrastructure
./network.sh --sourcePath ./org2.example.com --mode generateCrypto
./network.sh --sourcePath ./org2.example.com --mode generateArtifacts --network existing --mspId Org2MSP --outputFile Org2Config.json
./network.sh --sourcePath ./org2.example.com --mode createDockerComposeCA --domain example.com --org org2
./network.sh --sourcePath ./org2.example.com --mode up
sleep 30
./network.sh --mode joinChannel --cli cli.org2.example.com --peer peer0.org2.example.com:7051 --channelName channelone
./network.sh --mode joinChannel --cli cli.org2.example.com --peer peer1.org2.example.com:7051 --channelName channelone


./network.sh --sourcePath ./org1.example.com --mode createConfigUpdate --cli cli.org1.example.com --newOrgMspId Org2MSP --orderer orderer0.example.com:7050  --inputFile Org2Config.json --outputFile Org2Config.pb --channelName channelone
./network.sh --mode signConfigUpdate --cli cli.org1.example.com --inputFile Org2Config.pb
./network.sh --mode channelUpdateNewOrg --cli cli.org1.example.com  --inputFile Org2Config.pb --orderer orderer0.example.com:7050 --channelName channelone

# Chaincode installation

CC=marbles02/go

./cc-dev.sh --mode installChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --ccName marbles --version 1.0 --language golang --ccPath $CC
./cc-dev.sh --mode installChaincode --cli cli.org1.example.com --peer peer1.org1.example.com:7051 --ccName marbles --version 1.0 --language golang --ccPath $CC
./cc-dev.sh --mode installChaincode --cli cli.org2.example.com --peer peer0.org2.example.com:7051 --ccName marbles --version 1.0 --language golang --ccPath $CC
./cc-dev.sh --mode installChaincode --cli cli.org2.example.com --peer peer1.org2.example.com:7051 --ccName marbles --version 1.0 --language golang --ccPath $CC
./cc-dev.sh --mode instantiateChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --orderer orderer0.example.com:7050 --ccName marbles --version 1.0 --language golang --channelName channelone --args '{"Args":["init"]}' --policy "AND('Org1MSP.peer','Org2MSP.peer')"

# # ==== Invoke marbles ====
# ./cc-dev.sh --mode invokeChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["initMarble","marble1","blue","35","tom"]}'
# ./cc-dev.sh --mode invokeChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["initMarble","marble3","blue","70","tom"]}'
# ./cc-dev.sh --mode invokeChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["transferMarble","marble2","jerry"]}'
# ./cc-dev.sh --mode invokeChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["transferMarblesBasedOnColor","blue","jerry"]}'
# ./cc-dev.sh --mode invokeChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["delete","marble1"]}'

# # ==== Query marbles ====
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["readMarble","marble1"]}'
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["getMarblesByRange","marble1","marble3"]}'
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["getHistoryForMarble","marble1"]}'

# # Rich Query (Only supported if CouchDB is used as state database):
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["queryMarblesByOwner","tom"]}'
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["queryMarbles","{\"selector\":{\"owner\":\"tom\"}}"]}'

# # Rich Query with Pagination (Only supported if CouchDB is used as state database):
# ./cc-dev.sh --mode queryChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName channelone --ccName marbles --args '{"Args":["queryMarblesWithPagination","{\"selector\":{\"owner\":\"tom\"}}","3",""]}'

set +x

# ==== Invoke marbles ====
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["initMarble","marble1","blue","35","tom"]}'
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["initMarble","marble2","red","50","tom"]}'
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["initMarble","marble3","blue","70","tom"]}'
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["transferMarble","marble2","jerry"]}'
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["transferMarblesBasedOnColor","blue","jerry"]}'
# peer chaincode invoke -C channelone -n marbles -c '{"Args":["delete","marble1"]}'

# ==== Query marbles ====
# peer chaincode query -C channelone -n marbles -c '{"Args":["readMarble","marble1"]}'
# peer chaincode query -C channelone -n marbles -c '{"Args":["getMarblesByRange","marble1","marble3"]}'
# peer chaincode query -C channelone -n marbles -c '{"Args":["getHistoryForMarble","marble1"]}'

# Rich Query (Only supported if CouchDB is used as state database):
# peer chaincode query -C channelone -n marbles -c '{"Args":["queryMarblesByOwner","tom"]}'
# peer chaincode query -C channelone -n marbles -c '{"Args":["queryMarbles","{\"selector\":{\"owner\":\"tom\"}}"]}'

# Rich Query with Pagination (Only supported if CouchDB is used as state database):
# peer chaincode query -C channelone -n marbles -c '{"Args":["queryMarblesWithPagination","{\"selector\":{\"owner\":\"tom\"}}","3",""]}'