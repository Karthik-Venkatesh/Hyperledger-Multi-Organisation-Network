VERBOSE=false
CLI_TIMEOUT=10
CLI_DELAY=3
LANGUAGE=golang
FABRIC_START_DELAY=30

NETWORK_START_MODE_NEW="new"
NETWORK_START_MODE_EXISTING="existing"

PATH_DOCKER_BASE_TEMPLATE=../templates/docker/docker-compose-base.yml
PATH_DOCKER_CA_TEMPLATE=../templates/docker/docker-compose-ca-template.yaml

mkdir -p ./org-artifacts

function exportGoPath() {
  export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../../bin:${PWD}:$PATH
  export FABRIC_CFG_PATH=${PWD}/fabric-config
}

function desc() {
    echo
    echo " ____    _____      _      ____    _____ "
    echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
    echo "\___ \    | |     / _ \   | |_) |   | |  "
    echo " ___) |   | |    / ___ \  |  _ <    | |  "
    echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
    echo
    echo "Kafka network end-to-end test"
    echo
}

function endDesc() {
    echo
    echo "========= All GOOD, execution completed =========== "
    echo

    echo
    echo " _____   _   _   ____   "
    echo "| ____| | \ | | |  _ \  "
    echo "|  _|   |  \| | | | | | "
    echo "| |___  | |\  | | |_| | "
    echo "|_____| |_| \_| |____/  "
    echo
}

function printHelp() {
    echo "Usage: "
    echo "  network.sh <mode>  [<option> <option value>]"
    echo "    <mode> - one of 'generateCrypto', 'generateArtifacts', 'createDockerComposeCA', 'up', 'stop'"
    echo "      'tearDown', 'copyOrdererCerts', 'createConfigUpdate', 'createChannel', 'joinChannel', 'updateAnchorPeer'"
    echo "      'signConfigUpdate', 'channelUpdateNewOrg'"
    echo ""
    echo "      - 'generateCrypto' - generate crypto materials"
    echo "          > Required: --sourcePath"
    echo "      - 'generateArtifacts' - generate channel artifacts"
    echo "          > Required: --sourcePath, --channelName, --mspId, --network"
    echo "          - '--network'=new : Creates artifacts for new network with genesis block"
    echo "          - '--network'=existing : Creates artifacts json for existing network. --outputFile required"
    echo "      - 'createDockerComposeCA' - creates a docker-compose-ca.yaml file with ca private key"
    echo "          > Required: --sourcePath, --domain, --org"
    echo "      - 'up' - bring up the network with docker-compose up"
    echo "          > Required: --sourcePath"
    echo "      - 'stop' - stopping the containers."
    echo "          > Required: --sourcePath"
    echo "      - 'tearDown' - shut down the Docker containers for the system tests. remove chaincode docker images"
    echo "          > Required: --sourcePath"
    echo "      - 'copyOrdererCerts' - copying orderers tlscacerts to ../orderer-certs folder"
    echo "          > Required: --sourcePath, --domain"
    echo "      - 'createConfigUpdate' - Creating the update config for new organisation which is going to enter in the network."
    echo "                               The new organisation configuration json file name need to be in their msp id (ex: Org1MSP.json)"
    echo "                               The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --sourcePath, --channelName, --newOrgMspId, --orderer, --cli, --inputFile, --outputFile"
    echo "      - 'createChannel' - create new channel"
    echo "          > Required: --sourcePath, --channelName, --peer, --orderer, --cli"
    echo "      - 'joinChannel' - join peer to channel"
    echo "          > Required: --channelName, --peer, --cli"
    echo "      - 'updateAnchorPeer' - update anchor peer in channel"
    echo "          > Required: --sourcePath, --channelName, --mspId, --peer, --cli"
    echo "      - 'signConfigUpdate' - sign new organisation config .pb file"
    echo "                             The new organisation configuration .pb file name need to be in their msp id (ex: Org1MSP.pb)"
    echo "                             The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --inputFile, --cli"
    echo "      - 'channelUpdateNewOrg' - Add new org to channel"
    echo "                             The new organisation configuration .pb file name need to be in their msp id (ex: Org1MSP.pb)"
    echo "                             The file need to vailable in ./network-setup/org-artifacts folder"
    echo "          > Required: --channelName, --orderer, --inputFile, --cli"
    echo ""
    echo "    <options> - one of --sourcePath, --channelName, --mspId, --domain, --orderer, --network, --org, --peer, --help"
    echo "      --sourcePath - path of organisation source"
    echo "      --channelName - channel name to use"
    echo "      --mspId - msp id of cli organisation. ex: Org1MSP"
    echo "      --newOrgMspId - msp id of new org which is going to enter ins network. ex: Org1MSP"
    echo "      --domain - domain of network. ex: example.com"
    echo "      --orderer - orderer id to proceed channel configuration. ex: orderer0.example.com:7050"
    echo "      --network - newtork present status. 'new' or 'existing'"
    echo "      --org - organisation name. example: org1 (which is a part of org1.example.com)"
    echo "      --peer - peer id. example: peer0.org1.example.com:7051"
    echo "      --cli - cli docker id. example: cli.org1.example.com"
    echo "      --inputFile - input file name with extension which is going to be processed"
    echo "      --outputFile - output file name with extension which is processed"
    echo "      --help - help"
}

# Ask user for confirmation to proceed
function askProceed() {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y | "")
    echo "proceeding ..."
    ;;
  n | N)
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

function exitIfChannelNameNotInvalid() {
  if [ -z $CHANNEL_NAME ]; then
    echo "Error: channel name (--channelName) not provided. Exiting..."
    exit 1
  fi
}

function exitIfMspIdNotInvalid() {
  if [ -z $MSP_ID ]; then
    echo "Error: mspID (--mspId) not provided. Exiting..."
    exit 1
  fi
}

function exitIfNewOrgMspIdNotInvalid() {
  if [ -z $NEW_ORG_MSP_ID ]; then
    echo "Error: newOrgMspId (--newOrgMspId) not provided. Exiting..."
    exit 1
  fi
}

function exitIfDomainNotInvalid() {
  if [ -z $DOMAIN ]; then
    echo "Error: domain (--domain) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOrdererNotInvalid() {
  if [ -z $ORDERER ]; then
    echo "Error: orderer (--orderer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfOrgNotInvalid() {
  if [ -z $ORG ]; then
    echo "Error: Oragnisations (--org) not provided. Exiting..."
    exit 1
  fi
}

function exitIfPeerNotInvalid() {
  if [ -z $PEER ]; then
    echo "Error: Peer (--peer) not provided. Exiting..."
    exit 1
  fi
}

function exitIfCliNotInvalid() {
  if [ -z $CLI ]; then
    echo "Error: CLI (--cli) not provided. Exiting..."
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

function exitIfSourcePathNotavailable() {
  case "$MODE" in
    "generateCrypto"|"generateArtifacts"|"up"|"stop"|"tearDown"|"copyOrdererCerts"|"createDockerComposeCA"|"createChannel"|"updateAnchorPeer"|"createPeerAdminCard"|"importPeerAdminCard" )           
      if [ "$SOURCE_PATH" == "./" ]; then
        echo "--sourcePath must be defined. Exiting..."
        exit 1
      fi
      ;;
  esac
}

function generateCrypto() {

    set -e

    exportGoPath

    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"

    # remove previous crypto material and config transactions
    rm -fr ./crypto-config
    # create folders
    mkdir -p crypto-config

    # generate crypto material
    cryptogen generate --config=./fabric-config/crypto-config.yaml
    if [ "$?" -ne 0 ]; then
    echo "Failed to generate crypto material..."
    exit 1
    fi

    set +e
}

function generateArtifactsWithGenesis() {

  # remove previous config transactions
  rm -fr ./channel-artifacts
  # create folders
  mkdir -p channel-artifacts

  set -e

  exportGoPath

  echo
  echo "##########################################################"
  echo "##### Generate artifacts using configtxgen tool #########"
  echo "##########################################################"

  # generate genesis block for orderer
  configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  generateChannelConf
  generateChannelAnchor

  set +e
}

function generateChannelConf() {

  exitIfChannelNameNotInvalid

  exportGoPath

  # generate channel configuration transaction
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
}

function generateChannelAnchor() {
  
  exitIfChannelNameNotInvalid
  exitIfMspIdNotInvalid

  exportGoPath

  # generate anchor peer transaction
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/"$MSP_ID"anchors.$CHANNEL_NAME.tx -channelID $CHANNEL_NAME -asOrg $MSP_ID
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for $MSP_ID..."
    exit 1
  fi
}

function generateArtifactsJson() {

  exitIfMspIdNotInvalid
  exitIfOutPutFileNotInvalid
  
    set -e

    echo
    echo "##########################################################"
    echo "##### Generate artifacts using configtxgen tool #########"
    echo "##########################################################"

    # remove previous config transactions
    rm -fr ./channel-artifacts

    # create folders
    mkdir -p channel-artifacts

    exportGoPath

    # generate channel configuration transaction
    configtxgen -printOrg $MSP_ID > ./channel-artifacts/$OUTPUT_FILE
    if [ "$?" -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

    cp ./channel-artifacts/$OUTPUT_FILE ../org-artifacts

    set +e

}

function copyOrdererCerts() {

    exitIfDomainNotInvalid

    # remove previous orderer certificates
    rm -fr ../orderer-certs
    # create folders
    mkdir -p ../orderer-certs

    dir="ordererOrganizations/$DOMAIN/tlsca"
    mkdir -p ../orderer-certs/$dir
    cp ./crypto-config/$dir/tlsca.$DOMAIN-cert.pem  ../orderer-certs/$dir

}

function createDockerComposeCA() {
  exitIfDomainNotInvalid
  exitIfOrgNotInvalid

  cp $PATH_DOCKER_CA_TEMPLATE ./docker-config/docker-compose-ca.yaml

  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi
  CURRENT_DIR=$PWD
  cd crypto-config/peerOrganizations/$ORG.$DOMAIN/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  cd crypto-config/peerOrganizations/$ORG.$DOMAIN/tlsca/
  TLSCA_PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" ./docker-config/docker-compose-ca.yaml
  sed $OPTS "s/CA_ORG_DOMAIN/${ORG}.${DOMAIN}/g" ./docker-config/docker-compose-ca.yaml
  sed $OPTS "s/CA_CONTAINER/ca.${ORG}.${DOMAIN}/g" ./docker-config/docker-compose-ca.yaml
  if [ "$ARCH" == "Darwin" ]; then
    rm ./docker-config/docker-compose-ca.yamlt
  fi
}

function up() {
    desc
    
    copyDockerBaseFile
    docker-compose -f ./docker-config/docker-compose.yml down
    docker-compose -f ./docker-config/docker-compose.yml up -d
    
    CA_COMPOSE_FILE=./docker-config/docker-compose-ca.yaml
    if [ -f "$CA_COMPOSE_FILE" ]; then
      docker-compose -f $CA_COMPOSE_FILE down
      docker-compose -f $CA_COMPOSE_FILE up -d
    fi
}

function stop() {
    # stopping the containers. Note that this will remove all existing docker containers
    CA_COMPOSE_FILE=docker-config/docker-compose-ca.yaml
    if [ -f "$CA_COMPOSE_FILE" ]; then
      docker-compose -f $CA_COMPOSE_FILE stop
    fi

    copyDockerBaseFile
    docker-compose -f ./docker-config/docker-compose.yml stop
}

function tearDown() {
    # Shut down the Docker containers for the system tests.
    CA_COMPOSE_FILE=./docker-config/docker-compose-ca.yaml
    if [ -f "$CA_COMPOSE_FILE" ]; then
      docker-compose -f $CA_COMPOSE_FILE down
      rm $CA_COMPOSE_FILE
    fi

    copyDockerBaseFile
    docker-compose -f ./docker-config/docker-compose.yml down 
    docker rm $(docker ps -aq)
    docker rmi $(docker images scm-* -q)

    # remove the local state
    rm -f ~/.hfc-key-store/*

    # remove previous crypto material and config transactions
    rm -fr ./channel-artifacts
    rm -fr ./crypto-config
    rm -fr ./cards

    # Your system is now clean
}

function copyDockerBaseFile() {
  rm -f ./docker-config/docker-compose-base.yml
  cp $PATH_DOCKER_BASE_TEMPLATE ./docker-config/
}

function createChannel() {
  
    exitIfChannelNameNotInvalid
    exitIfCliNotInvalid
    exitIfOrdererNotInvalid
    exitIfPeerNotInvalid

    if [ ! -f "./channel-artifacts/$CHANNEL_NAME.tx" ]; then
      generateChannelConf
    fi 

    docker exec $CLI scripts/script.sh --mode createChannel \
      --channelName $CHANNEL_NAME \
      --peer $PEER \
      --orderer $ORDERER
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Channel creation failed"
        exit 1
    fi

}


function joinChannel() {
  exitIfChannelNameNotInvalid
  exitIfCliNotInvalid
  exitIfPeerNotInvalid

  docker exec $CLI scripts/script.sh --mode joinChannel \
    --channelName $CHANNEL_NAME \
    --peer $PEER 
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! joining to channel failed"
    exit 1
  fi
}


function updateAnchorPeer() {
  exitIfChannelNameNotInvalid
  exitIfMspIdNotInvalid
  exitIfCliNotInvalid
  exitIfPeerNotInvalid

  if [ ! -f "./channel-artifacts/"$MSP_ID"anchors.$CHANNEL_NAME.tx" ]; then
    generateChannelAnchor
  fi 

  docker exec $CLI scripts/script.sh --mode updateAnchorPeer \
    --channelName $CHANNEL_NAME \
    --peer $PEER \
    --orderer $ORDERER

}

function createConfigUpdate() {

  exitIfChannelNameNotInvalid
  exitIfNewOrgMspIdNotInvalid
  exitIfInputFileNotInvalid
  exitIfOutPutFileNotInvalid
  exitIfCliNotInvalid

  docker exec $CLI scripts/script.sh --mode createConfigUpdate \
    --channelName $CHANNEL_NAME \
    --newOrgMspId $NEW_ORG_MSP_ID \
    --orderer $ORDERER \
    --inputFile $INPUT_FILE \
    --outputFile $OUTPUT_FILE

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Failed to add new organisation details"
    exit 1
  fi

}

function signConfigUpdate() {
  exitIfInputFileNotInvalid
  exitIfCliNotInvalid
  
  docker exec $CLI scripts/script.sh --mode signConfigUpdate \
    --inputFile $INPUT_FILE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Failed to sign new organisation details"
    exit 1
  fi
}

function channelUpdateNewOrg() {
  exitIfChannelNameNotInvalid
  exitIfInputFileNotInvalid
  exitIfCliNotInvalid

  docker exec $CLI scripts/script.sh --mode channelUpdateNewOrg \
    --channelName $CHANNEL_NAME \
    --inputFile $INPUT_FILE \
    --orderer $ORDERER
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Failed to add update new organisation details in channel..."
      exit 1
  fi
}

function execute() {
  if [ "$MODE" == "generateCrypto" ]; then
    generateCrypto
  elif [ "$MODE" == "generateArtifacts" ]; then
    if [ "$NETWORK" == "$NETWORK_START_MODE_NEW" ]; then
      generateArtifactsWithGenesis
    elif [ "$NETWORK" == "$NETWORK_START_MODE_EXISTING" ]; then
      generateArtifactsJson
    else 
      echo "Error: --network not defined. Exiting." 
      exit 1
    fi
  elif [ "$MODE" == "up" ]; then
    up
  elif [ "$MODE" == "stop" ]; then
    stop
  elif [ "$MODE" == "tearDown" ]; then
    tearDown
  elif [ "$MODE" == "copyOrdererCerts" ]; then
    copyOrdererCerts
  elif [ "$MODE" == "createConfigUpdate" ]; then
    createConfigUpdate $@
  elif [ "$MODE" == "createChannel" ]; then
    createChannel
  elif [ "$MODE" == "joinChannel" ]; then
    joinChannel
  elif [ "$MODE" == "updateAnchorPeer" ]; then
    updateAnchorPeer
  elif [ "$MODE" == "signConfigUpdate" ]; then
    signConfigUpdate
  elif [ "$MODE" == "createDockerComposeCA" ]; then
    createDockerComposeCA
  elif [ "$MODE" == "channelUpdateNewOrg" ]; then
    channelUpdateNewOrg
  else
    printHelp
    exit 1
  fi
}

function parseParam() {
  SOURCE_PATH="./"
  while [ "$1" != "" ]; do
    case $1 in
      --sourcePath )           
        SOURCE_PATH=$2
        ;;
      --mode )           
        MODE=$2
        ;;
      --channelName )    
        CHANNEL_NAME=$2
        ;;
      --mspId )           
        MSP_ID=$2
        ;;
      --newOrgMspId )           
        export NEW_ORG_MSP_ID=$2
        ;;
      --domain )           
        DOMAIN=$2
        ;;
      --orderer )           
        ORDERER=$2
        ;;
      --network )           
        NETWORK=$2
        ;;
      --org )           
        ORG=$2
        ;;
      --peer )           
        PEER=$2
        ;;
      --cli )           
        CLI=$2
        ;;
      --inputFile )           
        INPUT_FILE=$2
        ;;
      --outputFile )           
        OUTPUT_FILE=$2
        ;;
      --help )           
        printHelp
        exit
        ;;
      * )
        echo "Invalid option: $1"
        echo "help: ./network.sh --help"       
        exit
        ;;
    esac
    shift
    shift
  done
}

parseParam $@

exitIfSourcePathNotavailable 

( cd $SOURCE_PATH
  execute
)
