#!/bin/bash

function printHelp() {
    echo "Usage: "
    echo "  script.sh <mode> [<option> <option value>]"
    echo "    <mode> - 'createChannel', 'joinChannel', 'updateAnchorPeer', 'createConfigUpdate', 'signConfigUpdate', 'channelUpdateNewOrg'"
    echo ""
    echo "      - 'createChannel' - create new channel"
    echo "          > Required: --channelName, --peer, --orderer"
    echo "      - 'joinChannel' - join peer to channel"
    echo "          > Required: --channelName, --peer"
    echo "      - 'updateAnchorPeer' - update anchor peer in channel"
    echo "          > Required: --channelName, --peer, --orderer"
    echo "      - 'createConfigUpdate' - Creating the update config for new organisation which is going to enter in the network"
    echo "                               The new organisation configuration json file name need to be in their msp id (ex: Org1MSP.json)"
    echo "                               The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --channelName, --newOrgMspId, --orderer, --inputFile, --outputFile"
    echo "      - 'signConfigUpdate' - Signing the config update pb for new orgaisation to enter the network"
    echo "                             The new organisation configuration .pb file name need to be in their msp id (ex: Org1MSP.pb)"
    echo "                             The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --inputFile"
    echo "      - 'channelUpdateNewOrg' - Add new org to channel"
    echo "                             The new organisation configuration .pb file name need to be in their msp id (ex: Org1MSP.pb)"
    echo "                             The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --channelName, --orderer, --inputFile"
    echo ""
    echo "    <options> - one of --channelName, --newOrgMspId, --orderer, --peer, --help"
    echo "      --channelName - channel name to use"
    echo "      --newOrgMspId - msp id of new org which is going to enter ins network. ex: Org1MSP"
    echo "      --orderer - orderer id to proceed channel configuration. ex: orderer0.example.com:7050"
    echo "      --peer - peer id. ex: peer0.org1.example.com"
    echo "      --inputFile - input file name with extension which is going to be processed"
    echo "      --outputFile - output file name with extension which is processed"
    echo "      --help - help"
}

DELAY=3

function exitIfChannelNameNotInvalid() {
  if [ -z $CHANNEL_NAME ]; then
    echo "Error: channel name (--channelName) not provided. Exiting..."
    exit 1
  fi
}

function exitIfNewOrgMspIdNotInvalid() {
  if [ -z $NEW_ORG_MSP_ID ]; then
    echo "Error: newOrgMspId (--newOrgMspId) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOrdererNotInvalid() {
  if [ -z $ORDERER ]; then
    echo "Error: orderer (--orderer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfPeerNotInvalid() {
  if [ -z $PEER ]; then
    echo "Error: Peer (--peer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfInputFileNotInvalid() {
  if [ -z $INPUT_FILE ]; then
    echo "Error: Input (--inputFile) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOutPutFileNotInvalid() {
  if [ -z $OUTPUT_FILE ]; then
    echo "Error: Output file name (--outputFile) not provided. Exiting..."
    exit 1
  fi
}

# import utils
. scripts/utils.sh

createChannel() {

  exitIfChannelNameNotInvalid
  exitIfOrdererNotInvalid
  exitIfPeerNotInvalid

	setGlobals $PEER

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o $ORDERER -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o $ORDERER -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
  exitIfChannelNameNotInvalid
  exitIfPeerNotInvalid
	
  joinChannelWithRetry
	echo "===================== $PEER joined channel '$CHANNEL_NAME' ===================== "
	sleep $DELAY
}

function updateAnchorPeer() {
  exitIfChannelNameNotInvalid
  exitIfOrdererNotInvalid
  exitIfPeerNotInvalid
  
  updateAnchorPeers
}

function createConfigUpdate() {
    
    exitIfNewOrgMspIdNotInvalid
    exitIfChannelNameNotInvalid
    exitIfOrdererNotInvalid
    exitIfInputFileNotInvalid
    exitIfOutPutFileNotInvalid

    # default orderer ordere0 and port is 7051

    set -e
    set -x

    peer channel fetch config config_block.pb -o $ORDERER -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'$NEW_ORG_MSP_ID'":.[1]}}}}}' config.json ./org-artifacts/$INPUT_FILE > modified_config.json

    createNewConfigUpdate $CHANNEL_NAME config.json modified_config.json ./org-artifacts/$OUTPUT_FILE

    set +x
    set +e
}

function channelUpdateNewOrg() {
    exitIfChannelNameNotInvalid
    exitIfInputFileNotInvalid
    exitIfOrdererNotInvalid

    set -x
    peer channel update -f ./org-artifacts/$INPUT_FILE -c $CHANNEL_NAME -o $ORDERER --tls --cafile $ORDERER_CA
    set +x
} 

function signConfigUpdate() {
  exitIfInputFileNotInvalid
  signConfigtxAsPeerOrg ./org-artifacts/$INPUT_FILE
}


function execute() {
  if [ "$MODE" == "createChannel" ]; then
    createChannel
  elif [ "$MODE" == "joinChannel" ]; then
    joinChannel
  elif [ "$MODE" == "updateAnchorPeer" ]; then
    updateAnchorPeer
  elif [ "$MODE" == "createConfigUpdate" ]; then
    createConfigUpdate
  elif [ "$MODE" == "signConfigUpdate" ]; then
    signConfigUpdate
  elif [ "$MODE" == "channelUpdateNewOrg" ]; then
    channelUpdateNewOrg
  else
    echo "execute"
    printHelp
    exit 1
  fi
}

function parseParam() {
  while [ "$1" != "" ]; do
    case $1 in
      --mode )           
        MODE=$2
        ;;
      --channelName )    
        export CHANNEL_NAME=$2
        ;;
      --newOrgMspId )           
        export NEW_ORG_MSP_ID=$2
        ;;
      --orderer )           
        export ORDERER=$2
        ;;
      --peer )           
        export PEER=$2
        ;;
      --inputFile )           
        INPUT_FILE=$2
        ;;
      --outputFile )           
        OUTPUT_FILE=$2
        ;;
      --help )           
        printHelp
        exit 1
        ;;
      * )           
        printHelp
        exit 1
        ;;
    esac
    shift
    shift
  done
}

parseParam $@
execute


