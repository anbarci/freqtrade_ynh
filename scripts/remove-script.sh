#!/bin/bash

#=================================================
# IMPORT GENERIC HELPERS
#=================================================

source _common.sh
source /usr/share/yunohost/helpers

#=================================================
# LOAD SETTINGS
#=================================================
ynh_script_progression --message="Loading installation settings..." --weight=1

app=$YNH_APP_INSTANCE_NAME

domain=$(ynh_app_setting_get --app=$app --key=domain)
port=$(ynh_app_setting_get --app=$app --key=port)
final_path=$(ynh_app_setting_get --app=$app --key=final_path)

#=================================================
# STANDARD REMOVE
#=================================================

# Remove the service from the list of services known by YunoHost (added from `yunohost service add`)
if ynh_exec_warn_less yunohost service status freqtrade >/dev/null
then
    ynh_script_progression --message="Removing freqtrade service integration..." --weight=1
    yunohost service remove freqtrade
fi

# Stop and remove the systemd service
ynh_script_progression --message="Stopping and removing the systemd service..." --weight=1
ynh_remove_systemd_config

# Remove the app directory securely
ynh_script_progression --message="Removing app main directory..." --weight=1
ynh_secure_remove --file="$final_path"

# Remove the data directory if --purge option is used
if [ "${YNH_APP_PURGE:-0}" -eq 1 ]
then
    ynh_script_progression --message="Removing app data directory..." --weight=1
    ynh_secure_remove --file="/home/yunohost.app/$app"
fi

# Remove the dedicated user
ynh_script_progression --message="Removing the dedicated system user..." --weight=1
ynh_system_user_delete --username=$app

# Remove a directory securely
ynh_script_progression --message="Removing various files..." --weight=1
ynh_secure_remove --file="/var/log/$app"

# Remove the log files
ynh_remove_logrotate

# Remove nginx configuration
ynh_script_progression --message="Removing NGINX web server configuration..." --weight=1
ynh_remove_nginx_config

#=================================================
# END OF SCRIPT
#=================================================

ynh_script_progression --message="Removal of $app completed" --last
