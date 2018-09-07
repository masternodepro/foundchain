#!/bin/bash

COIN_NAME="fchain"
CONFIG_FILE="${COIN_NAME}.conf"
DAEMON_FILE="${COIN_NAME}d"
CLI_FILE="${COIN_NAME}-cli"

BINARIES_PATH=/usr/local/bin
DAEMON_PATH="${BINARIES_PATH}/${DAEMON_FILE}"
CLI_PATH="${BINARIES_PATH}/${CLI_FILE}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function ask_user()
{
  read -e -p "$(echo -e ${YELLOW} Which user account does your masternode run under? ${NC})" USERNAME

  if [[ -z "${USERNAME}" ]]; then
    echo "${RED} A username is required to continue${NC}";
    ask_user
  fi
  
  HOME_FOLDER="/home/${USERNAME}/.${COIN_NAME}"
}

function stop_service()
{
  echo -e "${GREEN} Stopping the service.${NC}"

  systemctl stop ${USERNAME}.service
  sleep 5
}

function stop_node()
{
  echo -e "${GREEN} Stopping the masternode.${NC}"
  ${CLI_PATH} -datadir=${HOME_FOLDER} stop

  sleep 5
}

function start_service()
{
  echo -e "${GREEN} Starting the service.${NC}"
  systemctl start ${USERNAME}.service
  sleep 5
}

function check_block()
{
  local block=$(${CLI_PATH} -datadir=${HOME_FOLDER} getblockcount)
  
  if [[ $block -ne $LAST_BLOCK ]]; then
    LAST_BLOCK=$(${CLI_PATH} -datadir=${HOME_FOLDER} getblockcount)
    sleep 5

    echo -e "${GREEN} Checking block height ... ${block}${NC}"
    check_block
  fi
}

function reindex()
{
  echo -e "${GREEN} Starting the reindex process.${NC}"
  
  rm -rf ${HOME_FOLDER}/blocks/ 
  rm -rf ${HOME_FOLDER}/chainstate/
  rm -rf ${HOME_FOLDER}/sporks/
  rm -f ${HOME_FOLDER}/*.dat
  rm -f ${HOME_FOLDER}/*.log

  ${DAEMON_PATH} -datadir=${HOME_FOLDER} -reindex
  sleep 5
  ${CLI_PATH} -datadir=${HOME_FOLDER} addnode 45.77.122.108 onetry

  echo -e "${GREEN} Checking block height.${NC}"
  LAST_BLOCK=$(${CLI_PATH} -datadir=${HOME_FOLDER} getblockcount)
  sleep 5

  echo ""
  check_block
}

function post_reindex()
{
  echo ""

  chown -R ${USERNAME}: ${HOME_FOLDER}  
  echo "Waiting to restart service"
}

clear

echo
echo -e "${GREEN}"
echo -e "============================================================================================================="
echo
echo -e "                                    888888  dP\"\"b8 88  88    db    88 88b 88"
echo -e "                                    88__   dP   \`\" 88  88   dPYb   88 88Yb88"
echo -e "                                    88\"\"   Yb      888888  dP__Yb  88 88 Y88"  
echo -e "                                    88      YboodP 88  88 dP\"\"\"\"Yb 88 88  Y8" 
echo
echo                          
echo -e "${NC}"
echo -e " This script will reindex your ${COIN_NAME} masternode which will affect your rewards and your node will "
echo -e " need to be restarted from you wallet after this script runs."
echo
echo -e "${GREEN}"
echo -e "============================================================================================================="              
echo -e "${NC}"

read -e -p "$(echo -e ${YELLOW} Do you want to continue? [Y/N] ${NC})" CHOICE

if [[ ("${CHOICE}" == "n" || "${CHOICE}" == "N") ]]; then
  exit 1;
fi

ask_user
stop_service
reindex
stop_node
post_reindex
start_service

echo -e "${GREEN}"
echo -e " If no errors were reported above, re-indexing of the ${COIN_NAME} node is finished."
echo -e "${NC}"