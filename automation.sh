#!/bin/bash

# Colors makes things beautiful
export TERM=xterm

    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    blu=$(tput setaf 4)             #  blue
    cya=$(tput setaf 6)             #  cyan
    txtrst=$(tput sgr0)             #  Reset

update_repos_and_packages() {
        echo -e ${blu}"Updating Repos and System"
        sudo apt update && sudo apt upgrade -y
        echo -e ${grn}"Repos and System Update completed."${txtrst}
        wait
}
install_apache() {
        echo -e ${blu}"Apache web server installation"
        count=`dpkg --get-selections | grep apache | wc -l`

        if [ $count -eq 0 ]
        then
                echo -e ${blu}"Installing Apache web server..."${txtrst}
                sudo apt-get install apache2 -y
                wait
                echo -e ${grn}"Apache web server is installed successfully."${txtrst}
        else
                echo -e ${grn}"Apache web server already installed."${txtrst}
        fi
}
start_apache(){
        echo -e ${blu}"Checking if Apache web server is running..."
        count=`sudo systemctl status apache2 | grep -w active | wc -l`
        wait
        if [ $count != 0 ]; then
                echo -e ${grn}"Apache web server is running."${txtrst}
        else
                echo -e ${red}"Apache web server is dead. Starting the daemon..."${txtrst}
                sudo systemctl start apache2
                wait
                echo -e ${grn}"Apache web server is started successfully."${txtrst}
        fi
}
enable_apache() {
        echo -e ${blu}"Checking if Apache web server is enabled..."
        count=`sudo systemctl list-unit-files | grep enabled | grep apache | wc -l`
        wait
        if [ $count != 0 ]; then
                echo -e ${grn}"Apache web server is enabled already."${txtrst}
        else
                echo -e ${red}"Apache web server is not enabled. Enabling the service..."${txtrst}
                sudo systemctl enable apache2
                wait
                echo -e ${grn}"Apache web server is enabled successfully"${txtrst}
        fi
}
install_awscli() {
        echo -e ${blu}"AWS CLI installation"${txtrst}
        count=`dpkg --get-selections | grep awscli | wc -l`
        if [ $count -eq 0 ]
        then
                echo -e ${blu}"Installing AWS CLI..."${txtrst}
                sudo apt-get install awscli -y
                wait
        else
                echo -e ${grn}"AWS CLI is already installed."${txtrst}
        fi
}
upload_tar_archive() {
        echo -e ${cya}"Preparing to upload archives to S3..."${txtrst}
        timestamp=$(date '+%d%m%Y-%H%M%S')
        myname=Deepak
        s3_bucket=upgrad-deepak
        tar -cvf /tmp/$myname-httpd-logs-$timestamp.tar /var/log/apache2/*.log
        echo -e ${blu}"Uploading archives to S3..."${txtrst}
        aws s3 cp /tmp/$myname-httpd-logs-$timestamp.tar s3://$s3_bucket/$myname-httpd-logs-$timestamp.tar
}
book_keeping_logs() {
        inventory_file="/var/www/html/inventory.html"
        if [ -f "$inventory_file" ]; then
                echo -e ${grn}"$inventory_file file already exists."${txtrst}
        else
                echo -e ${blu}"Creating $inventory_file placeholder file..."${txtrst}
                echo "<b>Log Type &nbsp;&nbsp;&nbsp;&nbsp; Date Created &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Type &nbsp;&nbsp;&nbsp;&nbsp; Size</b><br>" > $inventory_file
        fi
        archive_size=`du -hs /tmp/$myname-httpd-logs-$timestamp.tar | awk  '{print $1}'`
        echo "<br>httpd-logs &nbsp;&nbsp;&nbsp; ${timestamp} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; tar &nbsp;&nbsp;&nbsp; ${archive_size}" >> $inventory_file
        echo -e ${grn}"Inventory File Written with Archive Logs details."${txtrst}
}
cron_job() {
        cron_job_file="/etc/cron.d/automation"
        if [ -f "$cron_job_file" ]; then
            echo -e ${grn}"$cron_job_file already exists."${txtrst}
        else
                echo -e ${blu}"Creating $cron_job_file file..."${txtrst}
                echo "10 1 * * * root bash /root/Automation_Project/automation.sh" > $cron_job_file
                echo -e ${grn}"$cron_job_file cron job file created."${txtrst}
        fi
}
update_repos_and_packages
install_apache
start_apache
enable_apache
install_awscli
upload_tar_archive
book_keeping_logs
cron_job
