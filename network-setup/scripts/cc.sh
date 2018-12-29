#!/bin/bash

TIMEOUT="10"
DELAY="3"

function printHelp() {
    echo "Usage: "
    echo "  cc.sh [<option> <option value>]"
    echo "    <mode> - 'installChaincode', 'instantiateChaincode', 'invokeChaincode', 'queryChaincode', 'upgradeChaincode'"
    echo ""
    echo "      - 'installChaincode' - Package the specified chaincode into a deployment spec and save it on the peer's path."
    echo "          > Required: --peer, --ccName, --ccPath, --version, --language"
    echo "      - 'instantiateChaincode' - Deploy the specified chaincode to the network."
    echo "          > Required: --peer, --orderer, --ccName, --version, --language, --channelName, --args, --policy"
    echo "      - 'invokeChaincode' -  Invoke the specified chaincode."
    echo "          > Required: --peer, --ccName, --channelName, --args"
    echo "      - 'queryChaincode' - Query using the specified chaincode"
    echo "          > Required: --peer, --ccName, --channelName, --args"
    echo "      - 'upgradeChaincode' - Upgrade chaincode."
    echo "          > Required: --peer, --orderer, --ccName, --channelName, --version, --args, --policy"
    echo ""
    echo "    <options> - one of --mode, --channelName, --orderer, --peer, --ccName, --ccPath, --version, --language, --args, --policy, --help"
    echo "      --mode - execution functionality"
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

  setGlobals $PEER

  set -x
  peer chaincode install -n ${CHAIN_CODE_NAME} -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on ${PEER} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode is installed ${PEER} on channel '$CHANNEL_NAME' ===================== "
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

  setGlobals $PEER

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

function invokeChaincode() {

  echo "Functionality need to be implemented"

  # exitIfPeerInvalid
  # exitIfCCNameInvalid
  # exitIfChannelNameInvalid
  # exitIfArgsInvalid

  # if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
  #   set -x
  #   peer chaincode invoke -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -c $ARGS
  #   res=$?
  #   set +x
  # else
  #   set -x
  #   peer chaincode invoke --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -c $ARGS
  #   res=$?
  #   set +x
  # fi
  # cat log.txt
  # verifyResult $res "Chaincode invoke on ${PEER} on channel '$CHANNEL_NAME' failed"
  # echo "===================== Chaincode invoke ${PEER} on channel '$CHANNEL_NAME'n succedded ===================== "
  # echo
}

function queryChaincode() {

  echo "Functionality need to be implemented"

  # exitIfPeerInvalid
  # exitIfCCNameInvalid
  # exitIfChannelNameInvalid
  # exitIfArgsInvalid

  # setGlobals $PEER

  # if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
  #   set -x
  #   peer chaincode query -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -c $ARGS
  #   res=$?
  #   set +x
  # else
  #   set -x
  #   peer chaincode query --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -c $ARGS
  #   res=$?
  #   set +x
  # fi
  # cat log.txt
  # verifyResult $res "Chaincode query on ${PEER} on channel '$CHANNEL_NAME' failed"
  # echo "===================== Chaincode query ${PEER} on channel '$CHANNEL_NAME'n succedded ===================== "
  # echo
  # return $res
}

function upgradeChaincode() {

  exitIfOrdererInvalid
  exitIfPeerInvalid
  exitIfCCNameInvalid
  exitIfChannelNameInvalid
  exitIfArgsInvalid
  exitIfVersionInvalid
  exitIfPolicyInvalid

  setGlobals $PEER

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode upgrade -o $ORDERER -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -v $VERSION -c $ARGS -P $POLICY
    res=$?
    set +x
  else
    set -x
    peer chaincode upgrade -o $ORDERER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHAIN_CODE_NAME} -v $VERSION -c $ARGS -P $POLICY
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode upgrade on  ${PEER} has failed"
  echo "===================== Chaincode is upgraded on  ${PEER} on channel '$CHANNEL_NAME' ===================== "
  echo
}

function execute() {
  echo $MODE
  if [ "$MODE" == "installChaincode" ]; then
    installChaincode
  elif [ "$MODE" == "instantiateChaincode" ]; then
    instantiateChaincode
  elif [ "$MODE" == "invokeChaincode" ]; then
    invokeChaincode
  elif [ "$MODE" == "queryChaincode" ]; then
    queryChaincode
  elif [ "$MODE" == "upgradeChaincode" ]; then
    upgradeChaincode
    return $?
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
