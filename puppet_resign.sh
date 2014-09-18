#!/bin/bash

##################################################################################
# DEPENDENCIES:                                                                  #
# PUBLIC KEY ON REMOTE SERVERS                                                   #
# SUDO USER ON REMOTE SERVERS                                                    #
#                                                                                #
# DESCRIPTION:                                                                   #
# LOGIN TO MACHINES AND RESIGN PUPPET CERTIFICATES (OR CHANGE PUPPET MASTER)     #
##################################################################################

#### VARS ####

# ARRAY OF MACHINES TO MIGRATE (ip,hostname)
MACHINES=('
1.2.3.4,hostname1
1.2.3.5,hostname2
')

# PUPPETMASTER IP
PUPPETMASTER=1.2.3.4

# SSH USER + PORT
USER=root
PORT=22

#### MAIN FUNCTION ####
main() {

  #LOOP THROUGH ALL MACHINES
  for server in ${MACHINES[@]}; do

    # DECLARE IP + HOSTNAME + DATE VARIABLES
    IP=${server%%,*}
    HOSTNAME=${server##*,}
    DATE=$(date)

    # INITIATE MACHINE
    initiate_new_machine $IP $HOSTNAME $DATE

    # SSH TO MACHINE AND EXECUTE COMMANDS (RESIGN PUPPET)
    ssh_to_machine $IP $PUPPETMASTER

    # DONE
    done_configuring $IP $HOSTNAME
  done
}

#### INITIATE_NEW_MACHINE FUNCTION ####
initiate_new_machine() {

  # NEW MACHINE START IN OUTPUT LOG
  echo "> MACHINE: ${1} (${2}) ---------------------" >> puppet_resign_output.log

  # NEW MACHINE START IN ERROR LOG
  echo "> MACHINE: ${1} (${2}) ---------------------" >> puppet_resign_error.log
}

#### SSH_TO_MACHINE FUNCTION ####
ssh_to_machine() {

  # SSH TO MACHINE, EXECUTE COMMANDS, AND WRITE STDOUT + STDERR TO LOGS
  ssh -o StrictHostKeyChecking=no -p $PORT -t $USER@$1 "
    sudo puppet -V
    sudo sed -i '/puppet/d' /etc/hosts
    echo '${2} puppet' | sudo tee --append /etc/hosts
    sudo find /var/lib/puppet -type f -exec rm -rf {} \;
    sudo puppet agent -t
    sudo /etc/init.d/puppet restart
  " 1>> puppet_resign_output.log 2>> puppet_resign_error.log
}

#### DONE_CONFIGURING FUNCTION ####
done_configuring() {

  GREEN="\x1B[0;32m"
  NC="\x1B[0m"

  echo -e "${GREEN}DONE CONFIGURING NEW PUPPET FOR SERVER ${1} (${2})${NC}"

  echo -e "\n\n" >> puppet_resign_output.log
  echo -e "\n\n" >> puppet_resign_error.log

  sleep 1
}

#### INITIATE ####
main
