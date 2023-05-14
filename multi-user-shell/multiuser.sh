#!/bin/bash
#######################################################
#Autohor: NaveenKumar Alla
#Date: 11 May 2023
#Description: MultiUseradd with password
######################################################


###Function for User Add################

user-add ()
    {
  USER=$1
  PASSWORD=$2
  shift; shift;
  # Having shifted twice, the rest is now comments ...
  COMMENTS=$@
  echo "Adding user $USER ..."
  echo `useradd -c "$COMMENTS" $USER`
 # echo `passwd $USER`
  echo $PASSWORD | `passwd --stdin $USER>>/tmp/chpassword.log`
  echo "`date` Added user $USER ($COMMENTS) with pass $PASSWORD">>/tmp/userdata.log
    }

# Main body of script starts here
###
echo "Start of script..."
user-add nani $(date | md5sum | cut -c1-12) nanialla2005@gmail.com
#user-add bilko worsepassword Sgt. Bilko the role model
echo "End of script..."
