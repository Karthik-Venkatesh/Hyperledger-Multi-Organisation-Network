#!/bin/bash

function printHelp() {
    echo "Usage: "
    echo "  cc-dev.sh [<option> <option value>]"
    echo "    <mode> - 'installChaincode', 'instantiateChaincode'"
    echo ""
    echo "      - 'installChaincode' - Installing the chaincode"
    echo "          > Required: --peer, --ccName, --ccPath, --version, --language"
    echo "      - 'instantiateChaincode' - Instantiating the chaincode"
    echo "          > Required: --peer, --orderer, --ccName, --version, --language, --channelName"
    echo ""
    echo "    <options> - one of --mode, --cli, --channelName, --orderer, --peer, --ccName, --ccPath, --version, --language, --help"
    echo "      --mode - execution functionality"
    echo "      --cli - cli docker id. example: cli.org1.example.com"
    echo "      --channelName - channel name to use"
    echo "      --orderer - orderer id to proceed channel configuration. ex: orderer0.example.com:7050"
    echo "      --peer - peer id. ex: peer0.org1.example.com:7051"
    echo "      --ccName - Chain code name"
    echo "      --ccPath - Chaincode path from chaincode folder"
    echo "      --version - Chaincode version"
    echo "      --language - Chaincode language(eg: golang)"
    echo "      --help - help"
}

function exitIfChannelNameInvalid() {
  if [ -z $CHANNEL_NAME ]; then
    echo "Error: channel name (--channelName) not provided. Exiting..."
    exit 1
  fi
}

function exitIfLanguageInvalid() {
  if [ -z $LANGUAGE ]; then
    echo "Error: ChainCode Langudage (--language) not provided. Exiting..."
    exit 1
  fi
}

function exitIfCCPathInvalid() {
  if [ -z $CC_SRC_PATH ]; then
    echo "Error: ChainCode Path (--ccPath) not provided. Exiting..."
    exit 1
  fi
}

function exitIfCCNameInvalid() {
  if [ -z $CHAIN_CODE_NAME ]; then
    echo "Error: Chaincode name (--ccName) not provided. Exiting..."
    exit 1
  fi
}

function exitIfVersionInvalid() {
  if [ -z $VERSION ]; then
    echo "Error: Chaincode version (--version) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOrdererInvalid() {
  if [ -z $ORDERER ]; then
    echo "Error: orderer (--orderer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfPeerInvalid() {
  if [ -z $PEER ]; then
    echo "Error: Peer (--peer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfCliInvalid() {
  if [ -z $CLI ]; then
    echo "Error: CLI (--cli) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOutPutInvalid() {
  if [ -z $OUTPUT ]; then
    echo "Error: Output (--output) not provided. Exiting..."
    exit 1
  fi
}

function installChaincode() {
  exitIfPeerInvalid
  exitIfCCNameInvalid
  exitIfCCPathInvalid
  exitIfVersionInvalid
  exitIfLanguageInvalid  
  docker exec $CLI scripts/cc.sh --mode installChaincode \
    --peer $PEER \
    --ccName $CHAIN_CODE_NAME \
    --ccPath $CC_SRC_PATH \
    --version $VERSION \
    --language $LANGUAGE
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Install chaincode failed"
      exit 1
  fi
}

function instantiateChaincode() {
  exitIfOrdererInvalid
  exitIfPeerInvalid
  exitIfCCNameInvalid
  exitIfVersionInvalid
  exitIfLanguageInvalid  
  exitIfChannelNameInvalid
  docker exec $CLI scripts/cc.sh --mode instantiateChaincode \
    --orderer $ORDERER \
    --peer $PEER \
    --ccName $CHAIN_CODE_NAME \
    --version $VERSION \
    --language $LANGUAGE \
    --channelName $CHANNEL_NAME 
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Instantiate chaincode failed"
      exit 1
  fi
}

# function chaincodeQuery() {
#   docker exec $CLI scripts/cc.sh --mode chaincodeQuery \
#     --channelName $CHANNEL_NAME \
#     --peer $PEER \
#     --orderer $ORDERER
#   if [ $? -ne 0 ]; then
#       echo "ERROR !!!! Channel creation failed"
#       exit 1
#   fi
# }

function execute() {
  if [ "$MODE" == "installChaincode" ]; then
    installChaincode
  elif [ "$MODE" == "instantiateChaincode" ]; then
    instantiateChaincode
  # elif [ "$MODE" == "chaincodeQuery" ]; then
  #   chaincodeQuery
  else
    printHelp
    exit 1
  fi
}

function parseParam() {
  while [ "$1" != "" ]; do
    case $1 in
      --cli )           
        CLI=$2
        ;;
      --mode )           
        MODE=$2
        ;;
      --channelName )    
        CHANNEL_NAME=$2
        ;;
      --language )    
        LANGUAGE=$2
        ;;
      --ccPath )    
        CC_SRC_PATH=$2
        ;;
      --ccName )    
        CHAIN_CODE_NAME=$2
        ;;
      --version )           
        VERSION=$2
        ;;
      --orderer )           
        ORDERER=$2
        ;;
      --peer )           
        PEER=$2
        ;;
      --output )           
        OUTPUT=$2
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

exitIfCliInvalid

execute

