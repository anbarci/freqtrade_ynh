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
path_url=$(ynh_app_setting_get --app=$app --key=path)
final_path=$(ynh_app_setting_get --app=$app --key=final_path)
port=$(ynh_app_setting_get --app=$app --key=port)

#=================================================
# CHECK VERSION
#=================================================

upgrade_type=$(ynh_check_app_version_changed)

#=================================================
# BACKUP BEFORE UPGRADE THEN ACTIVE TRAP
#=================================================
ynh_script_progression --message="Backing up the app before upgrading (may take a while)..." --weight=1

# Backup the current version of the app
ynh_backup_before_upgrade
ynh_clean_setup () {
    ynh_clean_check_starting
    # Restore it if the upgrade fails
    ynh_restore_upgradebackup
}
# Exit if an error occurs during the execution of the script
ynh_abort_if_errors

#=================================================
# STANDARD UPGRADE STEPS
#=================================================

# Stop services
ynh_script_progression --message="Stopping a systemd service..." --weight=1
ynh_systemd_action --service_name=$app --action="stop" --log_path="/var/log/$app/$app.log"

# Create a dedicated user
ynh_script_progression --message="Making sure dedicated user exists..." --weight=1
ynh_system_user_create --username=$app --home_dir="$final_path"

# Download, check integrity, uncompress and patch the source from app.src
ynh_script_progression --message="Upgrading source files..." --weight=1
ynh_setup_source --dest_dir="$final_path" --keep="user_data/config.json"

# FIXME: this should be handled by the core in the future
# Upgrade dependencies
ynh_script_progression --message="Upgrading dependencies..." --weight=1
ynh_install_app_dependencies $pkg_dependencies

#=================================================
# NGINX CONFIGURATION
#=================================================
ynh_script_progression --message="Upgrading NGINX web server configuration..." --weight=1

# Create a dedicated NGINX config
ynh_add_nginx_config

#=================================================
# SPECIFIC UPGRADE
#=================================================

# Install Freqtrade
ynh_script_progression --message="Installing Freqtrade..." --weight=10

pushd $final_path
    ynh_exec_warn_less sudo -u $app python3 -m venv env
    ynh_exec_warn_less sudo -u $app $final_path/env/bin/pip install --upgrade pip
    ynh_exec_warn_less sudo -u $app $final_path/env/bin/pip install -e .
popd

# Use logrotate to manage application logfile(s)
ynh_script_progression --message="Upgrading logrotate configuration..." --weight=1
ynh_use_logrotate --non-append

#=================================================
# INTEGRATE SERVICE IN YUNOHOST
#=================================================
ynh_script_progression --message="Integrating service in YunoHost..." --weight=1

yunohost service add $app --description="Cryptocurrency trading bot" --log="/var/log/$app/$app.log"

#=================================================
# START SYSTEMD SERVICE
#=================================================
ynh_script_progression --message="Starting a systemd service..." --weight=1

ynh_systemd_action --service_name=$app --action="start" --log_path="/var/log/$app/$app.log"

#=================================================
# END OF SCRIPT
#=================================================

ynh_script_progression --message="Upgrade of $app completed" --last
