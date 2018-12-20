
set -x

#*****************************************Org1*******************************************#

set -e
# Constructing org1.example.com infrastructure
./network.sh --sourcePath ./org1.example.com --mode generateCrypto
./network.sh --sourcePath ./org1.example.com --mode generateArtifacts --network new --mspId Org1MSP --channelName org2channel
./network.sh --sourcePath ./org1.example.com --mode createDockerComposeCA --domain example.com --org org1
./network.sh --sourcePath ./org1.example.com --mode copyOrdererCerts --domain example.com
./network.sh --sourcePath ./org1.example.com --mode up

sleep 30

set +e

#*****************************************Org2*******************************************#

# Creating org2channel
./network.sh --sourcePath ./org1.example.com --mode createChannel --cli cli.org1.example.com --channelName org2channel --peer peer0.org1.example.com:7051 --orderer orderer0.example.com:7050
./network.sh --mode joinChannel --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName org2channel
./network.sh --mode joinChannel --cli cli.org1.example.com --peer peer1.org1.example.com:7051 --channelName org2channel
./network.sh --sourcePath ./org1.example.com --mode updateAnchorPeer --cli cli.org1.example.com --peer peer0.org1.example.com:7051 --channelName org2channel --mspId Org1MSP --orderer orderer0.example.com:7050

# Constructing org2.example.com infrastructure
./network.sh --sourcePath ./org2.example.com --mode generateCrypto
./network.sh --sourcePath ./org2.example.com --mode generateArtifacts --network existing --mspId Org2MSP --outputFile Org2Config.json
./network.sh --sourcePath ./org2.example.com --mode createDockerComposeCA --domain example.com --org org2
./network.sh --sourcePath ./org2.example.com --mode up
sleep 30
./network.sh --mode joinChannel --cli cli.org2.example.com --peer peer0.org2.example.com:7051 --channelName org2channel
./network.sh --mode joinChannel --cli cli.org2.example.com --peer peer1.org2.example.com:7051 --channelName org2channel


./network.sh --sourcePath ./org1.example.com --mode createConfigUpdate --cli cli.org1.example.com --newOrgMspId Org2MSP --orderer orderer0.example.com:7050  --inputFile Org2Config.json --outputFile Org2Config.pb --channelName org2channel
./network.sh --mode signConfigUpdate --cli cli.org1.example.com --inputFile Org2Config.pb
./network.sh --mode channelUpdateNewOrg --cli cli.org1.example.com  --inputFile Org2Config.pb --orderer orderer0.example.com:7050 --channelName org2channel

set +x