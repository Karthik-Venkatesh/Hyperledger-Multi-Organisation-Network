
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
./cc-dev.sh --mode installChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --ccName cc1 --version 1.0 --language golang --ccPath chaincode_example02/go
./cc-dev.sh --mode installChaincode --cli cli.org1.example.com --peer peer1.org1.example.com:7051 --ccName cc1 --version 1.0 --language golang --ccPath chaincode_example02/go
./cc-dev.sh --mode installChaincode --cli cli.org2.example.com --peer peer0.org2.example.com:7051 --ccName cc1 --version 1.0 --language golang --ccPath chaincode_example02/go
./cc-dev.sh --mode installChaincode --cli cli.org2.example.com --peer peer1.org2.example.com:7051 --ccName cc1 --version 1.0 --language golang --ccPath chaincode_example02/go
./cc-dev.sh --mode instantiateChaincode --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --orderer orderer0.example.com:7050 --ccName cc1 --version 1.0 --language golang --channelName channelone

set +x