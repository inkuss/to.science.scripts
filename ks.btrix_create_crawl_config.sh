#!/bin/bash
# Shell-Skript, dass Crawler-Config nach Browsertrix posten soll
# KS 24.09.2025
source funktionen.sh
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"                                                           cd $scriptdir
source variables.conf

# Hole ein "Bären-Token"
httpResponse=`curl -s -XPOST -H "Content-Type: application/x-www-form-urlencoded; Accept: application/json" --data 'username='$BTRIX_ADMIN_USERNAME'&password='$BTRIX_ADMIN_PASSWORD'&grant_type=password' "http://$BTRIX_API_URL/auth/jwt/login"`
# dann access_token auslesen
TOKEN=`echo $httpResponse | jq '.access_token'`
TOKEN=$(stripOffQuotes $TOKEN)
#echo "TOKEN=$TOKEN"
# Get Crawler Configs
# curl -XGET -H "Authorization: Bearer $TOKEN" "http://$BTRIX_API_URL/orgs/$BTRIX_ORGID/crawlconfigs"
# Create Crawler Config
curl -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data '{"name":"Bergischer Verein für Familienkunde","description":null,"inactive":false,"jobType":"custom","config":{"seeds":[{"url":"https://www.bvff.de/"}],"scopeType":"prefix","include": "string","exclude":"","depth":-1,"limit":0,"extraHops":1,"lang":"de","blockAds":false,"behaviorTimeout":0,"pageLoadTimeout":0,"pageExtraDelay":0,"postLoadDelay":0,"workers":0,"headless":true,"generateWACZ":true,"combineWARC":true,"useSitemap":true,"failOnFailedSeed":false,"failOnContentCheck":false,"logging":"","behaviors":"autoscroll,autoplay,autofetch,siteSpecific","customBehaviors":[],"userAgent":"","selectLinks":["a[href]->href"],"clickSelector":"a","saveStorage":false},"tags":["BN"],"crawlTimeout":0,"maxCrawlSize":0,"browserWindows":2,"oid":"'$BTRIX_ORGID'","profileid":"","crawlerChannel":"default","proxyId":"","profileName":""}' "http://$BTRIX_API_URL/orgs/$BTRIX_ORGID/crawlconfigs/"
#{"added":true,"id":"151175e6-d3d2-48a3-80a3-d39428804c45","run_now_job":null,"storageQuotaReached":false,"execMinutesQuotaReached":false,"errorDetail":null}
