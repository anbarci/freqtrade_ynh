#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

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
        ynh_systemd_action --service_name="$app" --action="stop" --log_path="$data_dir/logs/freqtrade.log"
    fi
}

# Start Freqtrade
start_freqtrade() {
    local app="$1" 
    ynh_systemd_action --service_name="$app" --action="start" --log_path="$data_dir/logs/freqtrade.log" --line_match="Starting freqtrade"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
