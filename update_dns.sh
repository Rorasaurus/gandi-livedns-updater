# ============================================================
#
#   Author   :  Rory Swann
#   Function :  Updates Gandi Live DNS with current egress IP
#               for a set of subdomains.
#
# ============================================================
#!/usr/bin/env bash

# Check Gandi API key is defined. Should be fetched from environment.
if [ -z ${GANDI_API_KEY} ]; then
    echo "Couldn't find Gandi API key in environment variables"
    exit 1
fi

# Check the domain hosted on Gandi LiveDns is supplied
if [ -z ${GANDI_DOMAIN} ]; then
    echo "Couldn't find Gandi LiveDNS domain in environment variables"
    exit 1
fi

# Get subdomains from environment variables
subdomains=()
for domain in $(printenv | grep DOMAIN_); do
    value=${domain#*=}
    subdomains+=($value)
done

# Array of URLs which will kindly return IP address
urls=(
    "ifconfig.me"
    "ipinfo.io/ip"
)

# Get external IP address
for url in ${urls[@]}; do
    echo $url
    ip=$(curl --silent --connect-timeout 3 $url)
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        break
    fi
done

# #Get the current Zone for the provided domain
zone_ref=$(curl -s -H "X-Api-Key: ${GANDI_API_KEY}" \
    https://dns.api.gandi.net/api/v5/domains/${GANDI_DOMAIN} \
    | jq -r '.zone_records_href')

# Update the A Record of the subdomain using PUT
for subdomain in ${subdomains[@]}; do
    echo "Updating $subdomain"
    curl -D- -X PUT -H "Content-Type: application/json" \
        -H "X-Api-Key: $GANDI_API_KEY" \
        -d "{\"rrset_name\": \"$subdomain\",
             \"rrset_type\": \"A\",
             \"rrset_ttl\": 1200,
             \"rrset_values\": [\"$ip\"]}" \
        $zone_ref/$subdomain/A
done