#!/bin/bash

function printHelp() {
    echo "Usage: "
    echo "  cc-dev.sh [<option> <option value>]"
    echo "    <mode> - 'installChaincode', 'instantiateChaincode', , 'invokeChaincode', 'queryChaincode', 'upgradeChaincode'"
    echo ""
    echo "      - 'installChaincode' - Package the specified chaincode into a deployment spec and save it on the peer's path."
    echo "          > Required: --peer, --ccName, --ccPath, --version, --language"
    echo "      - 'instantiateChaincode' - Deploy the specified chaincode to the network."
    echo "          > Required: --peer, --orderer, --ccName, --version, --language, --channelName"
    echo "      - 'invokeChaincode' -  Invoke the specified chaincode."
    echo "          > Required: --peer, --ccName, --channelName, --args"
    echo "      - 'queryChaincode' - Query using the specified chaincode"
    echo "          > Required: --peer, --ccName, --channelName, --args"
    echo "      - 'upgradeChaincode' - Upgrade chaincode."
    echo "          > Required: --peer, --orderer, --ccName, --channelName, --version, --args, --policy"
    echo ""
    echo "    <options> - one of --mode, --cli, --channelName, --orderer, --peer, --ccName, --ccPath, --version, --language, --args, --policy, --help"
    echo "      --mode - execution functionality"
    echo "      --cli - cli docker id. example: cli.org1.example.com"
    echo "      --orderer - orderer id to proceed channel configuration. ex: orderer0.example.com:7050"
    echo "      --peer - peer id. ex: peer0.org1.example.com:7051"
    echo "      --channelName - The channel on which this command should be executed"
    echo "      --ccName - Name of the chaincode"
    echo "      --ccPath - Path to chaincode(from chaincode folder)"
    echo "      --version - Version of the chaincode specified in install/instantiate/upgrade commands"
    echo "      --language - Language the chaincode is written in (default \"golang\")"
    echo "      --args - Constructor message for the chaincode in JSON format (default \"{}\")"
    echo "      --policy - The endorsement policy associated to this chaincode"
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

function exitIfArgsInvalid() {
  if [ -z $ARGS ]; then
    echo "Error: Arguments (--args) not provided. Exiting..."
    exit 1
  fi
}

function exitIfPolicyInvalid() {
  if [ -z $POLICY ]; then
    echo "Error: Policy (--policy) not provided. Exiting..."
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
  exitIfArgsInvalid
  exitIfPolicyInvalid

  docker exec $CLI scripts/cc.sh --mode instantiateChaincode \
    --orderer $ORDERER \
    --peer $PEER \
    --ccName $CHAIN_CODE_NAME \
    --version $VERSION \
    --language $LANGUAGE \
    --channelName $CHANNEL_NAME \
    --args $ARGS \
    --policy $POLICY
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Instantiate chaincode failed"
      exit 1
  fi
}

function invokeChaincode() {
  echo "Functionality need to be implemented"

  # exitIfPeerInvalid
  # exitIfCCNameInvalid
  # exitIfChannelNameInvalid
  # exitIfArgsInvalid

  # docker exec $CLI scripts/cc.sh --mode invokeChaincode \
  #   --peer $PEER \
  #   --ccName $CHAIN_CODE_NAME \
  #   --channelName $CHANNEL_NAME \
  #   --args $ARGS
  # if [ $? -ne 0 ]; then
  #     echo "ERROR !!!! Chaincoden query failed"
  #     exit 1
  # fi
}

function queryChaincode() {

  echo "Functionality need to be implemented"

  # exitIfPeerInvalid
  # exitIfCCNameInvalid
  # exitIfChannelNameInvalid
  # exitIfArgsInvalid

  # docker exec $CLI scripts/cc.sh --mode queryChaincode \
  #   --peer $PEER \
  #   --ccName $CHAIN_CODE_NAME \
  #   --channelName $CHANNEL_NAME \
  #   --args $ARGS
  # if [ $? -ne 0 ]; then
  #     echo "ERROR !!!! Chaincoden query failed"
  #     exit 1
  # fi
}

function upgradeChaincode() {

  exitIfOrdererInvalid
  exitIfPeerInvalid
  exitIfCCNameInvalid
  exitIfChannelNameInvalid
  exitIfArgsInvalid
  exitIfVersionInvalid
  exitIfPolicyInvalid

  docker exec $CLI scripts/cc.sh --mode upgradeChaincode \
    --peer $PEER \
    --orderer $ORDERER \
    --ccName $CHAIN_CODE_NAME \
    --channelName $CHANNEL_NAME \
    --args $ARGS \
    --version $VERSION \
    --policy $POLICY 
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Chaincoden query failed"
      exit 1
  fi
}

function execute() {
  if [ "$MODE" == "installChaincode" ]; then
    installChaincode
  elif [ "$MODE" == "instantiateChaincode" ]; then
    instantiateChaincode
  elif [ "$MODE" == "invokeChaincode" ]; then
    invokeChaincode
  elif [ "$MODE" == "queryChaincode" ]; then
    queryChaincode
  elif [ "$MODE" == "upgradeChaincode" ]; then
    queryChaincode
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
      --policy )
        POLICY=$2
        ;;
      --args )
        ARGS=$2
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

