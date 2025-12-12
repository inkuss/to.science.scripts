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
# scopeType: prefix = Pages in Same Directory
# Here are the Browsertrix scope types:
# scopeType: page: Limits the crawl to just the initial URL provided, crawling only that single page.
# scopeType: page-spa: Similar to page, but it also includes any links that contain different hashtags, useful for Single-Page Applications.
# scopeType: prefix: Crawls all pages that share the same directory as the starting URL.
# scopeType: host: Expands the crawl to include all pages that share the same host (e.g., example.com) as the starting URL.
# scopeType: domain: Includes pages from the entire domain, including all its subdomains.
# scopeType: any: Crawls all pages linked from the starting page, following links indefinitely until other limits, such as depth, are reached.
# jobType: Crawl Type: A broader setting that can be single-page (similar to the page scope), all-links (similar to the any scope), or custom
# Cookies gehen über das Browser-Profile
# User Agents siehe hier: https://www.useragents.me/ - aber was soll ich in das Feld userAgent eingeben ?
#   vermutlich so etwas wie "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.3"
#   maxCrawlSize muss Integer sein
# curl -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data '{"name":"Bergischer Verein für Familienkunde","description":null,"inactive":false,"jobType":"custom","config":{"seeds":[{"url":"https://www.bvff.de/"}],"scopeType":"prefix","include": "string","exclude":"","depth":-1,"limit":0,"extraHops":1,"lang":"de","blockAds":false,"behaviorTimeout":0,"pageLoadTimeout":0,"pageExtraDelay":0,"postLoadDelay":0,"workers":0,"headless":true,"generateWACZ":true,"combineWARC":true,"useSitemap":true,"failOnFailedSeed":false,"failOnContentCheck":false,"logging":"","behaviors":"autoscroll,autoplay,autofetch,siteSpecific","customBehaviors":[],"userAgent":"","selectLinks":["a[href]->href"],"clickSelector":"a","saveStorage":false},"tags":["BN"],"crawlTimeout":0,"maxCrawlSize":0,"browserWindows":2,"oid":"'$BTRIX_ORGID'","profileid":"","crawlerChannel":"default","proxyId":"","profileName":""}' "http://$BTRIX_API_URL/orgs/$BTRIX_ORGID/crawlconfigs/"
#{"added":true,"id":"151175e6-d3d2-48a3-80a3-d39428804c45","run_now_job":null,"storageQuotaReached":false,"execMinutesQuotaReached":false,"errorDetail":null}
cid=151175e6-d3d2-48a3-80a3-d39428804c45

# Aktualisiere scopeType in Crawler Config nach "domain":
# man muss ALLES noch einmal posten, sonst wird es abgelöscht :-(
# curl -XPATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data '{"name":"Bergischer Verein für Familienkunde","description":null,"inactive":false,"jobType":"custom","config":{"seeds":[{"url":"https://www.bvff.de/"}],"scopeType":"domain","include": "string","exclude":"","depth":-1,"limit":0,"extraHops":1,"lang":"de","blockAds":false,"behaviorTimeout":0,"pageLoadTimeout":0,"pageExtraDelay":0,"postLoadDelay":0,"workers":0,"headless":true,"generateWACZ":true,"combineWARC":true,"useSitemap":true,"failOnFailedSeed":false,"failOnContentCheck":false,"logging":"","behaviors":"autoscroll,autoplay,autofetch,siteSpecific","customBehaviors":[],"userAgent":"to.science%20(https://github.com/hbz/to.science.api;mailto:toscience@hbz-nrw.de)","selectLinks":["a[href]->href"],"clickSelector":"a","saveStorage":false},"tags":["BN"],"crawlTimeout":0,"maxCrawlSize":"10000000000","browserWindows":2,"oid":"'$BTRIX_ORGID'","profileid":"","crawlerChannel":"default","proxyId":"","profileName":""}' "http://$BTRIX_API_URL/orgs/$BTRIX_ORGID/crawlconfigs/$cid"
# {"updated":true,"settings_changed":true,"metadata_changed":false,"updatedRunning":false,"storageQuotaReached":false,"execMinutesQuotaReached":false,"started":null}

# Jetzt den Crawl starten:
curl -XPOST -H "Authorization: Bearer $TOKEN" "http://$BTRIX_API_URL/orgs/$BTRIX_ORGID/crawlconfigs/$cid/run"
# {"started":"manual-20250925160147-151175e6-d3d"}
