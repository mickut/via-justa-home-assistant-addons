
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
	for i in {1..${len}}; do str=${str}*; done
    sanitized_value=${str}$(echo ${2} | grep -o ...$)

    bashio::log.info "Setting ${1} to ${sanitized_value}"
    export "${1}=${2}"
}

get_tz() {
    curl -sSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/info | jq -r '.data.timezone'
}

restart_ha() {
    curl -X POST -sSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/restart
}

execute() {
    for domain in $(bashio::config 'domains'); do
        bashio::log.debug "checking domain ${domain}"
        args="${1} --domains ${domain}"

        bashio::log.debug "running command: lego ${1} renew --days ${renew_threshold} --renew-hook restart_ha"
        bashio::log.info "Certificate for domain ${domain} found, checking if renew needed"
        lego ${args} renew --days ${renew_threshold} --renew-hook restart_ha
    done
}