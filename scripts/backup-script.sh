#!/bin/bash

#=================================================
# IMPORT GENERIC HELPERS
#=================================================

source _common.sh  
source /usr/share/yunohost/helpers

#=================================================
# DECLARE DATA AND CONF FILES TO BACKUP
#=================================================
ynh_script_progression --message="Declaring files to be backed up..." --weight=1

#=================================================
# BACKUP THE APP MAIN DIR
#=================================================

ynh_backup --src_path="$final_path"

#=================================================
# BACKUP THE DATA DIR
#=================================================

ynh_backup --src_path="/home/yunohost.app/$app" --is_big

#=================================================
# BACKUP THE NGINX CONFIGURATION
#=================================================

ynh_backup --src_path="/etc/nginx/conf.d/$domain.d/$app.conf"

#=================================================
# BACKUP THE SYSTEMD CONFIGURATION
#=================================================

ynh_backup --src_path="/etc/systemd/system/$app.service"

#=================================================
# BACKUP LOGROTATE
#=================================================

ynh_backup --src_path="/etc/logrotate.d/$app"

#=================================================
# BACKUP THE LOG FILES
#=================================================

ynh_backup --src_path="/var/log/$app" --is_big

#=================================================
# END OF SCRIPT
#=================================================

ynh_script_progression --message="Backup of $app completed" --last
