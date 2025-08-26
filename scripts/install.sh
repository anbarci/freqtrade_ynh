#!/bin/bash

#=================================================
# IMPORT GENERIC HELPERS
#=================================================

source _common.sh
source /usr/share/yunohost/helpers

#=================================================
# INITIALIZE AND STORE SETTINGS
#=================================================

ynh_script_progression --message="Storing installation settings..." --weight=1

# Retrieve arguments from manifest
domain=$YNH_APP_ARG_DOMAIN
path_url=$YNH_APP_ARG_PATH
admin=$YNH_APP_ARG_ADMIN
password=$YNH_APP_ARG_PASSWORD
webserver_enabled=$YNH_APP_ARG_WEBSERVER_ENABLED
dry_run=$YNH_APP_ARG_DRY_RUN

app=$YNH_APP_INSTANCE_NAME

# Store settings
ynh_app_setting_set --app=$app --key=domain --value=$domain
ynh_app_setting_set --app=$app --key=path --value=$path_url
ynh_app_setting_set --app=$app --key=admin --value=$admin
ynh_app_setting_set --app=$app --key=password --value=$password
ynh_app_setting_set --app=$app --key=webserver_enabled --value=$webserver_enabled
ynh_app_setting_set --app=$app --key=dry_run --value=$dry_run

#=================================================
# CREATE DEDICATED USER
#=================================================
ynh_script_progression --message="Creating a system user..." --weight=1

# System user is automatically created by YunoHost v2 resources

#=================================================
# SETUP SOURCE FILES
#=================================================
ynh_script_progression --message="Setting up source files..." --weight=3

# Set permissions on install directory
chmod 750 "$install_dir"
chmod -R o-rwx "$install_dir"
chown -R $app:www-data "$install_dir"

# Set permissions on data directory  
chmod 750 "$data_dir"
chmod -R o-rwx "$data_dir"
chown -R $app:www-data "$data_dir"

#=================================================
# INSTALL FREQTRADE
#=================================================
ynh_script_progression --message="Installing Freqtrade..." --weight=20

pushd "$install_dir"
    # Create Python virtual environment
    ynh_exec_as $app python3 -m venv venv
    
    # Upgrade pip and install Freqtrade
    ynh_exec_as $app $install_dir/venv/bin/pip install --upgrade pip setuptools wheel
    ynh_exec_as $app $install_dir/venv/bin/pip install freqtrade[complete]
    
popd

#=================================================
# CREATE FREQTRADE CONFIGURATION
#=================================================
ynh_script_progression --message="Creating Freqtrade configuration..." --weight=2

# Create config.json
cat > "$data_dir/user_data/config.json" << EOF
{
    "max_open_trades": 3,
    "stake_currency": "USDT",
    "stake_amount": "unlimited", 
    "tradable_balance_ratio": 0.99,
    "fiat_display_currency": "USD",
    "dry_run": $([[ $dry_run -eq 1 ]] && echo "true" || echo "false"),
    "dry_run_wallet": 1000,
    "cancel_open_orders_on_exit": false,
    "trading_mode": "spot",
    "unfilledtimeout": {
        "entry": 10,
        "exit": 10,
        "exit_timeout_count": 0,
        "unit": "minutes"
    },
    "entry_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1,
        "price_last_balance": 0.0,
        "check_depth_of_market": {
            "enabled": false,
            "bids_to_ask_delta": 1
        }
    },
    "exit_pricing": {
        "price_side": "same", 
        "use_order_book": true,
        "order_book_top": 1
    },
    "exchange": {
        "name": "binance",
        "key": "",
        "secret": "",
        "ccxt_config": {},
        "ccxt_async_config": {},
        "pair_whitelist": [
            "BTC/USDT",
            "ETH/USDT"
        ],
        "pair_blacklist": []
    },
    "pairlists": [
        {"method": "StaticPairList"}
    ],
    "telegram": {
        "enabled": false,
        "token": "",
        "chat_id": ""
    },
    "api_server": {
        "enabled": $([[ $webserver_enabled -eq 1 ]] && echo "true" || echo "false"),
        "listen_ip_address": "127.0.0.1",
        "listen_port": $port,
        "verbosity": "error",
        "enable_openapi": false,
        "jwt_secret_key": "$(ynh_string_random --length=50)",
        "CORS_origins": [],
        "username": "$admin",
        "password": "$password"
    },
    "bot_name": "freqtrade_$app",
    "initial_state": "running",
    "force_entry_enable": false,
    "internals": {
        "process_throttle_secs": 5
    }
}
EOF

# Set proper permissions on config
chown -R $app:$app "$data_dir/user_data/"

#=================================================
# SYSTEM CONFIGURATION
#=================================================
ynh_script_progression --message="Adding systemd configuration..." --weight=1

# Create systemd service file
ynh_add_systemd_config

#=================================================
# NGINX CONFIGURATION  
#=================================================

if [ $webserver_enabled -eq 1 ]; then
    ynh_script_progression --message="Configuring NGINX web server..." --weight=1
    # Create NGINX config
    ynh_add_nginx_config
fi

#=================================================
# SETUP LOGROTATE
#=================================================
ynh_script_progression --message="Configuring log rotation..." --weight=1

ynh_use_logrotate --logfile="$data_dir/logs/freqtrade.log"

#=================================================
# INTEGRATE SERVICE IN YUNOHOST
#=================================================
ynh_script_progression --message="Integrating service in YunoHost..." --weight=1

yunohost service add $app --description="Cryptocurrency trading bot" --log="$data_dir/logs/freqtrade.log"

#=================================================
# START SYSTEMD SERVICE
#=================================================
ynh_script_progression --message="Starting Freqtrade service..." --weight=2

ynh_systemd_action --service_name=$app --action="start" --log_path="$data_dir/logs/freqtrade.log" --line_match="Starting freqtrade"

#=================================================
# END OF SCRIPT
#=================================================

ynh_script_progression --message="Installation of $app completed" --last
