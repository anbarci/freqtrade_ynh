#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# App version
YNH_APP_VERSION="2025.7"

#=================================================
# PERSONAL HELPERS
#=================================================

# Check if Freqtrade is running
is_freqtrade_running() {
    local app="$1"
    if systemctl is-active --quiet "$app"; then
        return 0
    else
        return 1
    fi
}

# Stop Freqtrade safely 
stop_freqtrade() {
    local app="$1"
    if is_freqtrade_running "$app"; then
        ynh_systemd_action --service_name="$app" --action="stop" --log_path="/home/yunohost.app/$app/logs/freqtrade.log"
    fi
}

# Start Freqtrade
start_freqtrade() {
    local app="$1" 
    ynh_systemd_action --service_name="$app" --action="start" --log_path="/home/yunohost.app/$app/logs/freqtrade.log" --line_match="Starting freqtrade"
}

# Create Freqtrade systemd service
create_freqtrade_service() {
    local app="$1"
    local install_dir="$2"
    local data_dir="/home/yunohost.app/$app"
    
    cat > "/etc/systemd/system/$app.service" << EOF
[Unit]
Description=Freqtrade cryptocurrency trading bot
After=network.target
Wants=network.target

[Service]
Type=simple
User=$app
Group=$app
WorkingDirectory=$install_dir
Environment=PATH=$install_dir/venv/bin
ExecStart=$install_dir/venv/bin/freqtrade trade --config $data_dir/user_data/config.json --datadir $data_dir/user_data
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$app

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$app.service"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
