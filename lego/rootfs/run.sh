#!/usr/bin/with-contenv bashio
CONFIG_PATH=/data/options.json

source /opt/functions.sh

CERT_PATH=/ssl/lego
mkdir -p ${CERT_PATH}
mkdir -p ${CERT_PATH}/certificates

declare cmd
declare args
declare challenge
declare renew_threshold
declare log_level
declare dns_resolver

## defaults
# set log.level
if bashio::config.has_value 'log_level'; then
    bashio::log.level $(bashio::config 'log_level')
fi

# Set timezone
cp /usr/share/zoneinfo/$(get_tz) /etc/localtime
bashio::log.debug "config::timezone $(get_tz)"

# Set challenge
challenge=$(config challenge "http")
bashio::log.debug "config::challenge ${challenge}"

# Set renew_threshold
renew_threshold=$(config renew_threshold "30")
bashio::log.debug "config::renew_threshold ${renew_threshold} days"

# Set check_time
check_time=$(config check_time "04:00")
bashio::log.debug "config::check_time ${check_time}"

# set dns_resolver
dns_resolver=$(config dnsresolver "")
bashio::log.debug "config::dnsresolver ${dns_resolver}"

bashio::log.debug "config::provider $(bashio::config 'provider')"
bashio::log.debug "config::domains $(bashio::config 'domains')"
bashio::log.debug "config::email $(bashio::config 'email')"
bashio::log.debug "config::restart $(bashio::config 'restart')"
bashio::log.debug "config::addons $(bashio::config 'addons')"

# Export env vars
for var in $(bashio::config 'env_vars|keys'); do
    name=$(bashio::config "env_vars[${var}].name")
    value=$(bashio::config "env_vars[${var}].value")
    
    env_export ${name} ${value}
done

bashio::log.info "using challenge ${challenge}"

args="--accept-tos --email $(bashio::config 'email') --path ${CERT_PATH}"

# Log domain list
for domain in $(bashio::config 'domains'); do
    sans=(${domain//,/ })
    bashio::log.info "Monitoring certificate for ${sans[0]}"
done

# select challenge
if [ "${challenge}" == "dns" ]; then
    args="${args} --dns $(bashio::config 'provider')"
    if [ "${dns_resolver}" != "" ]; then
        args="${args} --dns.resolvers ${dns_resolver}"
    fi
else
    args="${args} --http"
fi

# create new certificates
for domain in $(bashio::config 'domains'); do
    sans=(${domain//,/ })
    bashio::log.debug "Checking for certificate ${CERT_PATH}/certificates/${sans[0]//[*]/_}.crt existence"
    if [[ ! -f "${CERT_PATH}/certificates/${sans[0]//[*]/_}.crt" ]]; then
        bashio::log.info "Certificate for domain ${sans[0]} not found, issuing"
        domainargs=$args
        for san in ${sans[@]}; do
            domainargs="${domainargs} -d ${san}"
        done
        bashio::log.debug "running command: lego ${domainargs} run"
        lego ${domainargs} run
    else
        bashio::log.info "Certificate for domain ${sans[0]} found"
    fi    
done


while true
do
    # check if certificate needs to be renewed
    update ${args}

    # Calculate the sleep duration until the next check_time
    current_time=$(date +"%H:%M")
    check_time_hour=$(echo "$check_time" | cut -d':' -f1)
    check_time_minute=$(echo "$check_time" | cut -d':' -f2)

    if [[ "$current_time" > "$check_time" ]]; then
        next_check_time=$(date -d "+1 day $check_time" +"%s")
    else
        next_check_time=$(date -d "today $check_time" +"%s")
    fi

    current_time=$(date +"%s")
    sleep_duration=$((next_check_time - current_time))
    if [[ $sleep_duration -lt 0 ]]; then
        sleep_duration=$((sleep_duration + 86400)) # Add one day (86400 seconds)
    fi

    # Sleep until the next check_time
    sleep "$sleep_duration"
done