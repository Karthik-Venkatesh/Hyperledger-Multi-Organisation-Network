#!/bin/bash

TIMEOUT="10"
DELAY="3"

function printHelp() {
    echo "Usage: "
    echo "  cc.sh [<option> <option value>]"
    echo "    <mode> - 'installChaincode', 'instantiateChaincode'"
    echo ""
    echo "      - 'installChaincode' - Installing the chaincode"
    echo "          > Required: --peer, --ccName, --ccPath, --version, --language"
    echo "      - 'instantiateChaincode' - Instantiating the chaincode"
    echo "          > Required: --peer, --orderer, --ccName, --version, --language, --channelName"
    echo ""
    echo "    <options> - one of --mode, --channelName, --orderer, --peer, --ccName, --ccPath, --version, --language, --help"
    echo "      --mode - execution functionality"
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

function exitIfOutPutInvalid() {
  if [ -z $OUTPUT ]; then
    echo "Error: Output (--output) not provided. Exiting..."
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

function verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
    exit 1
  fi
}

setGlobals() {
  PEER=$1
  CORE_PEER_ADDRESS=$PEER
}

function installChaincode() {
  exitIfPeerInvalid
  exitIfCCNameInvalid
  exitIfCCPathInvalid
  exitIfVersionInvalid
  exitIfLanguageInvalid

  set -x
  peer chaincode install -n ${CHAIN_CODE_NAME} -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
  res=$?
  set +x
  cat log.txt
  echo
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

  # while 'peer chaincode' command can get the orderer endpoint from the peer
  # (if join was successful), let's supply it directly as we know it using
  # the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode instantiate -o $ORDERER -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -l ${LANGUAGE} -v ${VERSION} -c $ARGS -P  $POLICY >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode instantiate -o $ORDERER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -l ${LANGUAGE} -v ${VERSION} -c $ARGS -P $POLICY >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode instantiation on ${PEER} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode is instantiated ${PEER} on channel '$CHANNEL_NAME' ===================== "
  echo
}


function execute() {
  echo $MODE
  if [ "$MODE" == "installChaincode" ]; then
    installChaincode
  elif [ "$MODE" == "instantiateChaincode" ]; then
    instantiateChaincode
  else
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
      --language )
        export LANGUAGE=$2
        ;;
      --ccPath )
        export CC_SRC_PATH="github.com/chaincode/$2"
        ;;
      --ccName )
        export CHAIN_CODE_NAME=$2
        ;;
      --version )
        export VERSION=$2
        ;;
      --orderer )
        export ORDERER=$2
        ;;
      --peer )
        export PEER=$2
        setGlobals $PEER
        ;;
      --output )
        OUTPUT=$2
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
execute
