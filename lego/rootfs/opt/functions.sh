
# Call: config <config key> <default value>
config() {
    if bashio::config.has_value "$1"; then
        echo $(bashio::config "$1")
    else
        echo $2
    fi
}

# Call: env_export <key> <value>
env_export() {
    len=$((${#2} - 3))
    str=""
    for i in $(seq ${len}); do str=${str}*; done
    sanitized_value=${str}$(echo ${2} | grep -o ...$)
    
    bashio::log.debug "Setting ${1} to ${sanitized_value}"
    export "${1}=${2}"
}

get_tz() {
    curl -sSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/info | jq -r '.data.timezone'
}

update() {
    args="${@}"
    for domain in $(bashio::config 'domains'); do
        bashio::log.debug "checking domain ${domain}"
        domainargs=$args
        sans=(${domain//,/ })
        for san in ${sans[@]}; do
            domainargs="${domainargs} -d ${san}"
        done
        
        if [[ -f "${CERT_PATH}/certificates/${sans[0]//[*]/_}.crt" ]]; then
            bashio::log.info "Certificate for domain ${sans[0]} found, checking if renew needed"
            if $(bashio::config 'restart'); then
                bashio::log.debug "running command: lego ${domainargs} renew --days ${renew_threshold} --renew-hook /opt/restart_ha_hook.sh"
                lego ${domainargs} renew --days ${renew_threshold} --renew-hook /opt/restart_ha_hook.sh
            else
                bashio::log.debug "running command: lego ${domainargs} renew --days ${renew_threshold}"
                lego ${domainargs} renew --days ${renew_threshold}
                bashio::log.info "Certificate for domain ${domain} was renewed, manual restart of Home-Assistant is required"
            fi
        else
            bashio::log.error "Certificate for domain ${sans[0]} not found, did not renew"
        fi
    done
}

restart_addons() {
    if [ "$(bashio::config 'addons')" != null ]; then
        for addon in $(bashio::config 'addons'); do
            restart_addon ${addon}
        done
    fi
}

restart_addon() {
    msg=$(curl -X POST -sSL -o /dev/null -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons/$1/restart)
    if [ $? -ne 0 ] ; then
        bashio::log.error "Error restarting addon ${1}: $msg | jq -r '.message'"
    else
        bashio::log.info "Restarted addon $1"
    fi
}
