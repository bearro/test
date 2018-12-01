#!/bin/bash

export LC_ALL="en_US.UTF-8"
set -e

#Sleep time

sleep_time=2

#temporary remove when want capability to re-run
sudo rm tst.sh* 2>/dev/null #remove previous version installed

: '
-------ANSI color codes:-----------------------
Black        0;30     Dark Gray     1;30
Red          0;31     Light Red     1;31
Green        0;32     Light Green   1;32
Brown/Orange 0;33     Yellow        1;33
Blue         0;34     Light Blue    1;34
Purple       0;35     Light Purple  1;35
Cyan         0;36     Light Cyan    1;36
Light Gray   0;37     White         1;37
----------------------------------------------
'


# ----To Run Script: --------- 
: '

wget https://raw.githubusercontent.com/bearro/PAC_MN_status/master/All_Status_Check.sh && chmod +x All_Status_Check.sh && ./All_Status_Check.sh

'

#color usage establishment
NC='\033[0m' # No color
HEAD='\033[1;36m'
BLUE='\033[1;34m' 
GREEN='\033[1;32m'
DGREEN='\033[0;32m'
RED='\033[1;31m' 
YELL='\033[1;33m'


#Script Outline:
#1. MN Process Check
#2. Sentinel Check
#3. MN Status Checks
#4. Masternode Version Check - V:12.5.1 - P:70214
#5. Check current block and hash on explorer.paccoin.net
#6. For October 2018 Fork  'Block - 158418' BlockHash Check 
#7. Memory and Swap Check
#8. Disk Usage Check
#9. Checking of @foxd's service is installed


#script start

echo -e     "################${YELL}PACCOIN Community Release${NC}##################"
echo -e "${BLUE}####################${RED}-- REV_3.0 --${BLUE}###################${NC}"
echo -e  "${RED}#           MN diagnostics By @Bearro             #${NC}"
echo -e  "${RED}#  Thanks to contrib: @Fozzyblob, @dijida, @foxD  #${NC}"
echo           "####################################################"
echo ""
echo ""



#1. MN Process Check

echo -e "${HEAD}== 1. MN Process Check ==${NC}"
is_pac_running=`ps ax | grep -v grep | grep pac | wc -l`
	if [ $is_pac_running -gt 0 ]; then
		echo -e "${GREEN}PASSED: ${NC}Process is Running${NC}";
		check_1="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}Process failed, pac process is not running${NC}";
		check_1="${RED}FAIL${NC}";
			while true; do
			read -p "Would you like to start the MN process? (y/n)" yn
			case $yn in
			[Yy]* ) sudo ~/paccoind; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
			esac
			done
	fi
	
echo " "
sleep $sleep_time


#2. Sentinel Check

echo -e "${HEAD}== 2. Sentinel Check ==${NC}"
mn_sentinel=$(crontab -l)
mn_needed="* * * * * cd ~/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log"

	if echo "$mn_sentinel" | grep -q "$mn_needed"; 
	then
		echo -e "${GREEN}PASSED: ${NC}Sentinel is installed${NC}"
		check_2="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}Sentinel is not running, here is the output:${NC}"
		echo -e "$mn_sentinel" 
		echo -e "when it should be:'* * * * * cd ~/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log'"
		check_2="${RED}FAIL${NC}";
	fi
	
echo " "
sleep $sleep_time

#3. MN Status Checks

echo -e "${HEAD}== 3. MN Status Checks ==${NC}"

mn_status=$(./paccoin-cli masternode status | grep status)

	if echo "$mn_status" | grep -q 'Masternode successfully started'; 
	then
		echo -e "${GREEN}PASSED: ${NC}MN is enabled${NC}"	
		check_3="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}MN is in following state${NC}"
		echo -e "$mn_status"
		check_3="${RED}FAIL${NC}";	
	fi
	
mn_sync=$(./paccoin-cli mnsync status | grep AssetID)
	if echo "$mn_sync" | grep -q '999';
	then
		echo -e "${GREEN}PASSED: ${NC}MN is synced ${NC}"	
		check_3="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}MN sync is in the following state${NC}"
		./paccoin-cli mnsync status | grep --color=auto 'AssetID\|AssetName'
		check_3="${RED}FAIL${NC}"; 	
	fi

echo " "
sleep $sleep_time

#4. Masternode Version Check - V:12.5.1 - P:70214


echo -e "${HEAD}== 4. Masternode Version Check - V:12.5.1 - P:70214 ==${NC}"

version=$(./paccoin-cli getinfo | grep '"version"')

	if echo "$version" | grep -q '120501'; 
	then
		echo -e "${GREEN}PASSED: ${NC}MN is on correct version${NC}"
		check_4="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}Masternode is on incorrect version, your version:${NC}"
		./paccoin-cli getinfo | grep --color=auto '"version"'
		check_4="${RED}FAIL${NC}"; 
	fi
	
proto=$(./paccoin-cli getinfo | grep protocol)
	
	if echo "$proto" | grep -q '70214';
	then
		echo -e "${GREEN}PASSED: ${NC}MN is on correct protocol${NC}"
		check_4="${GREEN}PASS${NC}";
	else
		echo -e "${RED}FAILED: ${NC}Masternode is on incorrect protocol, your protocol:${NC}"
		./paccoin-cli getinfo | grep --color=auto 'protocol'
		check_4="${RED}FAIL${NC}"; 
	fi

echo " "
sleep $sleep_time

#5. Check current block and hash on explorer.paccoin.net


echo -e "${HEAD}== 5. Check current block and hash on explorer.paccoin.net ==${NC}" 

block_mn=$(./paccoin-cli getblockchaininfo | grep 'blocks\|bestblockhash')
block_web=$(curl http://usa.pacblockexplorer.com:3002/api/getblockcount 2>/dev/null)

	if echo "$block_mn" | grep -q "$block_web"; 
	then
		echo -e "${GREEN}PASSED: ${NC}MN on correct network block ${NC}"
		check_5="${GREEN}PASS${NC}";	
	else
		echo -e "${RED}FAILED: ${NC}MN is on inccorrect block, please try again later if this is a new node${NC}"
		echo -e "${NC} You block number is: ${RED} $block_mn ${NC} however,"
		echo -e "${NC} Online number is: ${RED} $block_web ${NC} however,"
		check_5="${RED}FAIL${NC}"; 		
	fi
echo " "
sleep $sleep_time

#6. For October 2018 Fork  'Block - 158418' BlockHash Check


echo -e "${HEAD}== 6. For October 2018 Fork  'Block - 158418' BlockHash Check ==${NC}"
	
block_oct18fork_mn=$(./paccoin-cli getblockhash 158418)

	if echo "$block_oct18fork_mn" | grep -q '0000000000000595a2a004a27026439bbfeddcbff7200585421a7fe3a51237be'; 
	then
		echo -e "${GREEN}PASSED: ${NC}MN on correct block hash after October 2018 network fork ${NC}"
		check_6="${GREEN}PASS${NC}";	
	else
		echo -e "${RED}FAILED: ${NC} If this is a new node and $block_mn < 158418 please try again later. if ${NC}"
		echo -e "${NC} You block number is: ${RED} $block_mn > 158418 ${NC} however, you wlill need to reindex your node"		
		check_6="${RED}FAIL${NC}"; 
	fi

echo " "
sleep $sleep_time

#7. Memory and Swap Check


echo -e "${HEAD}== 7. Memory and Swap Check ==${NC}"
mem_check=$(free -g|awk '/^Mem:/{print $2}')
swap_check=$(sudo swapon -s)
	if [[ "$mem_check" -lt "4"  &&  -z "$swap_check" ]]; then
   		echo -e "${RED}Process Doesn't Have Enough Memory, Running Swap Memory${NC}..."
			while true; do
			read -p "Would you like to install 4BG of swap space? This is a PAC Requirement. (y/n)" yn
			case $yn in
			[Yy]* ) sudo fallocate -l 4G /swapfile;
			sudo chmod 600 /swapfile;
			sudo mkswap /swapfile;
			sudo swapon /swapfile;
			echo -e "${GREEN}Newly created memory Breakdown::${NC}";
			echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab;
			free -h; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
			esac
			done
			check_7="${RED}FAIL${NC}"; 
	else
   		echo -e "${GREEN}PASSED: ${NC}Enough Memory is installed."
		check_7="${GREEN}PASS${NC}";
	fi

echo " "
sleep $sleep_time

#8. Disk Usage Check


echo -e "${HEAD}== 8. Disk Usage Check ==${NC}"

disk_usage=$(df -h / | awk '{ print $5 }' | tail -n 1| cut -d'%' -f1)

	if [ $disk_usage -gt 75 ]; 
	then
		echo -e "${RED}FAILED: ${NC} Your VPS is low on diskspace: $disk_usage > 75% full"
		check_8="${RED}FAIL${NC}"; 	
	else
		echo -e "${GREEN}PASSED: ${NC} Your VPS has enough free space: $disk_usage < 75% full"	
		check_8="${GREEN}PASS${NC}";	
	fi

echo " "
sleep $sleep_time


#9. Checking of @foxd's service is installed


echo -e "${HEAD}== 9. Checking of @foxd's service is installed  ==${NC}"

    if [ $(systemctl is-active pacd.service) == "active" ] ; then
    	echo -e "${GREEN}PASSED: ${NC}pacd.service service running";
		check_9="${GREEN}PASS${NC}";
    elif [ $(systemctl is-active paccoind.service) == "active" ] ; then
    	echo -e "${GREEN}PASSED: ${NC}pacoind.service service running${NC}";
		check_9="${GREEN}PASS${NC}";
    else
    	echo -e "${RED}No pacd or paccoind service running.. it is recommended you install for reliability..${NC}";
		while true; do
		read -p "would you like to install @foxD's auto-restart service? [recommended] (y/n)" yn
		case $yn in
		[Yy]* )  sudo wget https://gist.githubusercontent.com/foxrtb/b703ae761472c5599c4d83ab0d3d62ae/raw/e8913deb9e1b7cc9c649febd2942930e4f6f5127/add-systemd-from-script;
		chmod +x add-systemd-from-script; 
		./add-systemd-from-script; 
		echo -e "${GREEN}Fox'ds service has been installed..${NC}";
		break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
    		esac
		done
		check_9="${RED}FAIL${NC}"; 
    fi
    

echo " "
sleep $sleep_time

echo -e "${HEAD}== Results Summary ==${NC}"
echo -e "#1. [$check_1] MN Process Check"
echo -e "#2. [$check_2] Sentinel Check"
echo -e "#3. [$check_3] MN Status Check"
echo -e "#4. [$check_4] Masternode Version/Protocol Check"
echo -e "#5. [$check_5] Current block Check" 
echo -e "#6. [$check_6] October 2018 Fork Check"
echo -e "#7. [$check_7] Memory and Swap Check"
echo -e "#8. [$check_8] Disk Usage Check"
echo -e "#9. [$check_9] @foxd's Service Check"
echo -e "-------------------------------------"
echo -e ""
echo -e "${DGREEN}Status Checks All Complete.. ${NC} scroll up to use the information to help determine the next step needed in diagnostics. 
You can copy the 'Results Summary' section to social platforms to get further help from a PAC moderator"
echo -e "${BLUE}Thank you for supporting the ${YELL}PAC Network!! ${NC}"
