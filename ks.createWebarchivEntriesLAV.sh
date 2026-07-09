#!/bin/bash
# Autor: Ingolf Kuss, hbz
# Erstellungsdatum: 03.07.2026
# Beschreibung: Erstellt Webpages und Webschnitte für vom LAV gesammelte Archivdateien anhand einer CSV-Datei
# Änderungshistorie
# +------------------------------+----------------------------------------------------------------------------------------
# | Bearbeiter      | Datum      | Grund
# +------------------------------+----------------------------------------------------------------------------------------
# | Ingolf Kuss     | 03.07.2026 | Neuanlage
# +------------------------------+----------------------------------------------------------------------------------------
# Nummernkreise auf aion:    100 -  9.999 : Webpages des LAV (werden durch dieses Skript angelegt)
#                         10.000 - 39.999 : Webpages der drei LBs (durch das Skript ks.createWebarchivEntries.sh angelegt)
#                         40.000 -          Webschnitte (LBs und LAV) (z.Zt. bis 51.987, bevor dieses Skript läuft)
#                                             die vom LAV werden durch dieses Skript angelegt.
# "Nummernkreise" auf iphthime:
#                             10 -  3.181   Webschnitte und Webpages der LBs (bis 26.01.2026, 16:39 Uhr).
#                          4.000 - 14.000   Webpages des LAV (werden durch dieses Skript angelegt)
#                         20.967 -          Webschnitte und Webpages der LBs und des LAV (seit 26.01.2026, 18:15 Uhr; z.Zt. bis 21.695)
set -o nounset
source funktionen.sh
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $scriptdir
source variables.conf

usage() {
  cat <<EOF
  Erstellt Webpages und Webschnitte für vom LAV gesammelte Archivdateien anhand einer CSV-Datei
  Die CSV-Datei enthät: Titel;URL;Verzeichnis;Anzahl WARCs;Crawler;
  Beispielaufrufe:       ./ks.createWebarchivEntriesLAV.sh -f 2 -t 11 -b 4001 -i ../src/Webcrawls_LAV_NRW_2025_2026-06-30.csv  >> ../logs/ks.createWebarchivEntriesLAV.2-11.log 
                       -- legt 10 Webpages im Namensraum 4001 bis 4010 an, sowie Webschnitte für die dazugehörigen, mitgelieferten Webarchive
			./ks.createWebarchivEntriesLAV.sh -f 35 -t 35 -b 4028 -i ../src/Webcrawls_LAV_NRW_2025_2026-06-30.csv  >> ../logs/ks.createWebarchivEntriesLAV.35.log
                       -- legt eine Webpage mit PID 4028 an, sowie Webschnitte für die dazugehörigen, mitgelieferten Webarchive

  Optionen:
   - b [PID]         Beginn-PID; die erste PID im Nummernkreis für Webpages, die angelegt werden soll. Zählt dann hoch.
                         Standard: leer (=> PID wird zufällig vergeben). Webschnitt-PIDs werden zufällig vergeben.
   - f [von]         von; erste zu bearbeitende Zeile der CSV-Datei, Standard: $von
   - h               Hilfe (dieser Text)
   - i [Input-Datei] Webarchiv-Daten im CSV-Format, Dateiname. Default: $csv_datei
   - l [Bib-Kürzel]  Landesbibliotheks-Kürzel (hier nur LAV), Standardwert: $lb
   - s               silent off (nicht still), Standardwert: $silent_off
   - t [bis]         bis; letzte zu bearbeitende Zeile der CSV-Datei. Setze auf 0 oder -1 für "alle". Standard: $bis
   - v               verbose (gesprächig), Standardwert: $verbose
EOF
  exit 0
  }

function nextLine {
	printf "WARN: Archivdateien werden nicht verschoben und Webschnitt wird nicht angelegt.\n"
	cd $olddir
	if [ -n "$pid" ]; then
		pid=$(($pid+1))
	fi
}

# Default-Werte
beginnPid="4001"
von=2
csv_datei="/opt/toscience/src/Webcrawls_LAV_NRW_2025_2026-06-30.csv"
lb="LAV"
silent_off=0
bis=11
verbose=0

# Auslesen der Optionen und Kommandozeilenparameter
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "b:f:h?i:l:st:v" opt; do
    case "$opt" in
    b)  beginnPid=$OPTARG
        ;;
    f)  von=$OPTARG
        ;;
    h|\?) usage
        ;;
    i)  csv_datei=$OPTARG
        ;;
    l)  lb=$OPTARG
        ;;
    s)  silent_off=1
        ;;
    t)  bis=$OPTARG
        ;;
    v)  verbose=1
        ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# weitere Verarbeitung der Kommandozeilenparameter
if [ ! -f $csv_datei ]; then
  echo "ERROR: ($csv_datei) ist keine reguläre Datei !"
  exit 0
fi
curlopts=""
if [ $silent_off != 1 ]; then
  curlopts="$curlopts -s"
fi
if [ $verbose == 1 ]; then
  curlopts="$curlopts -v"
fi


echo "BACKEND=$BACKEND"
echo "Lege LAV-Webpages und -Webschnitte an anhand von Datei: $csv_datei"
if [ -n "$beginnPid" ]; then
  echo "erste Pid: $beginnPid"
fi
echo "erste Zeile: $von"
echo "letzte Zeile: $bis"
echo "Landesbibliotheks-Kürzel: $lb"

# get encoding format
encoding=$(encoding $csv_datei)
echo "encoding=$encoding"
# change encoding to utf8
export LC_CTYPE= LC_ALL="de_DE.UTF-8"
export LANG="de_DE"
echo "INFO: Erzeuge Datei $csv_datei.UTF-8"
iconv -f $encoding -t utf8 $csv_datei > $csv_datei.UTF-8
echo

# ********************************
# *** BEGINN Hauptverarbeitung ***
# ********************************
# Lies die Input-Datei Zeile für Zeile ein
n=0
pid=$beginnPid
while read zeile; do
	# Die gelieferte CSV-Datei Zeile für Zeile einlesen
        n=$(($n+1))
	if [ $n -lt $von ]; then
		continue
	fi
	if [ $bis -gt 0 ] && [ $n -gt $bis ]; then
		continue
	fi
	if [[ $zeile == ^* ]]; then
              	# Kommentarzeile
                continue
        fi
	printf "Zeile Nr. $n\n"
	# Split lines at semicolon
	## Mask spaces by <
	zeile_maskiert=$(echo $zeile | tr " " "<")
	arr=($(echo $zeile_maskiert | tr ";" "\n"))
        Titel=$(echo ${arr[0]} | tr "<" " ")
        URL=$(echo ${arr[1]} | tr "<" " ")
        Intervall="einmal jährlich"
        # subDomainKZ=$(echo ${arr[4]} | tr "<" " ")  # "X" falls mit Subdomains
        crawlSubdomains=true
	Verzeichnis=$(echo ${arr[2]} | tr "<" " ")
	anz_warcs=$(echo ${arr[3]} | tr "<" " ")
	crawler=$(echo ${arr[4]} | tr "<" " " | tr '[:upper:]' '[:lower:]')
	if [ "$crawler" = "browsertrix" ]; then crawler="btrix"; fi
	warcDate=""
        if [ ${#arr[@]} -gt 5 ]; then
		warcDate=$(echo ${arr[5]} | tr "<" " ")
        fi

	echo "Titel: $Titel"
	echo "URL: $URL"
	echo "Intervall: $Intervall"
	# if [ -n "$subDomainKZ" ]; then
	#	echo "subDomainKZ: $subDomainKZ"
	# fi
	echo "crawlSubdomains: $crawlSubdomains"
	echo "Verzeichnis: $Verzeichnis"
	echo "Anzahl WARCs: $anz_warcs"
	echo "Crawler: $crawler"
	if [ -n "$warcDate" ]; then
		echo "WARC-Date: $warcDate" # Format: "2025-11-28T02:18:52Z" = UTC
	fi
	if [ -n "$pid" ]; then
		echo "PID: $pid"
	fi


	# Jetzt eine Webpage anlegen
	Gatherconf="{\"name\":\"$NAMESPACE:$pid\",\"active\":false,\"robotsPolicy\":\"ignore\",\"maxCrawlSize\":0,\"urlsExcluded\":[\"(?i)(.(avi|wmv|mpe?g|mp3|mp4|mov|webm))$\",\"(?i)(suche|kalender|terminplaner).*$\"]"
	if [ "$crawler" = "heritrix" ]; then
		Gatherconf=$Gatherconf",\"crawlerSelection\":\"$crawler\",\"agentIdSelection\":\"LAV_Heritrix\",\"deepness\":12,\"waitSecBtRequests\":3,\"waitRetry\":120,\"tries\":10}"
	elif [ "$crawler" = "browsertrix" ]; then
		Gatherconf=$Gatherconf",\"crawlerSelection\":\"$crawler\",\"agentIdSelection\":\"LAV_Browsertrix\",\"deepness\":-1\"waitSecBtRequests\":0,\"waitRetry\":120}"
	elif [ "$crawler" = "wget" ]; then
		Gatherconf=$Gatherconf",\"crawlerSelection\":\"$crawler\",\"agentIdSelection\":\"Wget\",\"deepness\":12,\"waitSecBtRequests\":4}"
	else
		Gatherconf=$Gatherconf"}"
	fi
	printf "INFO: Creating a Webpage für Verzeichnis %s\n" $Verzeichnis
	printf "INFO: Using Gatherconf %s\n" $Gatherconf
	retcode=`./createWebpage.sh $curlopts "$Titel" "$URL" "$Intervall" "$pid" "$crawlSubdomains" "$Gatherconf"`
	echo $retcode
	olddir=$PWD
	if [[ "$retcode" =~  ^.*ERROR.*$ ]]; then
		printf "ERROR: Webpage zum Titel \"%s\", URL \"%s\", pid %s konnte nicht  angelegt werden!\n" "$Titel" $URL $NAMESPACE:$pid
		nextLine
		continue
	fi
	printf "INFO: Eine Webpage zum Titel \"%s\", URL \"%s\", pid %s wurde angelegt.\n" "$Titel" $URL $NAMESPACE:$pid
	echo

	
	# Jetzt die im angegebenem Verzeichnis mitgelieferten Archivdateien auswerten:
	# -  Zeitstempel extrahieren
	# -  Namen einer Archivdatei auswählen
	zeitstempel=""
	warcFilename=""
	if [ "$crawler" = "wget" ]; then
		# Crawl-Datum der Excel-Datei entnehmen
		zeitstempel=`date '+%Y%m%d%H%M%S' -d "$warcDate"` # Datumszeitstempel in lokaler Zeit
	fi
	lieferverzeichnis="/sftp/lav/$Verzeichnis"
	if [ ! -d "$lieferverzeichnis" ]; then
		printf "ERROR: Lieferverzeichnis %s nicht gefunden!\n" $lieferverzeichnis
		nextLine
		continue
	fi
	cd /sftp/lav/$Verzeichnis
	for archivdatei in *.warc.gz; do
		if [ ! -e "$archivdatei" ]; then break; fi
		if [[ "$archivdatei" =~ ^WEB-([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})[0-9]{3}-00000-.*\.warc\.gz$ ]] \
		|| [[ "$archivdatei" =~ ^.*([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})[0-9]{3}-00000\.warc\.gz$ ]] \
		|| [[ "$archivdatei" =~ ^.*manual-([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})-[0-9a-f]{8}-[0-9a-f]{3}-[0-9]{17}-0\.warc\.gz$ ]]; then
			# Heritrix: Datumsstempel variiert => den kleinsten nehmen (Startdatum); das ist der von der Datei "-00000"; z.B. "WEB-20250225153259290-00000-61314~thinkcentre~8443.warc.gz" oder "tieraerztekammer-nordrhein-de-20250904111305942-00000.warc.gz"
			# Browsertrix: das 1. Datum zählt; z.B. "my-organization-zfu-de-manual-20251215115117-47f2ea43-240-20251215115125472-1.warc.gz"
			warcDate=`printf "%s-%s-%sT%s:%s:%sZ" ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]} ${BASH_REMATCH[5]} ${BASH_REMATCH[6]}` # Zeit in UTC
			zeitstempel=`date '+%Y%m%d%H%M%S' -d "$warcDate"` # Datumszeitstempel in lokaler Zeit
			warcFilename=$archivdatei
			break
		fi
		if [[ "$archivdatei" =~ ^.*-00000\.warc\.gz$ ]]; then
			# Wget
			warcFilename=$archivdatei
			break
		fi
	done
	if [ -z "${zeitstempel:-}" ]; then
		printf "ERROR: Zeitstempel für den Crawl im Verzeichnis %s kann nicht ermittelt werden!\n" $Verzeichnis
		nextLine
		continue
	fi
	if [ -z "${warcFilename:-}" ] || [ ! -e "$warcFilename" ]; then
		printf "ERROR: Archivdatei für den Crawl im Verzeichnis %s kann nicht ermittelt werden!\n" $Verzeichnis
		nextLine
		continue
	fi
	printf "INFO: Zeitstempel %s (lokaler Zeit) für diesen Crawl ermittelt.\n" $zeitstempel
	printf "INFO: Archivdatei %s für diesen Crawl ermittelt (es kann noch weitere geben).\n" $warcFilename

	
	# Die Archvidateien in ein Verzeichnis ~/lav-data/$NAMESPACE:$pid/$zeitstempel verschieben (auf einer mit Wayback geteilten Platte)
	crawlverz=$ARCHIVE_HOME/lav-data/$NAMESPACE:$pid/$zeitstempel
	mkdir -p $crawlverz
	printf "INFO: Crawlverzeichnis %s angelegt.\n" $crawlverz
	for archivdatei in *.warc.gz *.warc; do
		if [ ! -e "$archivdatei" ]; then continue; fi
		mv $archivdatei $crawlverz
		printf "INFO: Archivdatei %s in das Crawlverzeichnis %s verschoben.\n" $archivdatei $crawlverz
	done
	# Das Ursprungsverzeichnis löschen (es sollte leer sein)
	cd ..
	rmdir $Verzeichnis
	printf "INFO: Ursprungsverzeichnis /sftp/lav/%s wurde gelöscht.\n" $Verzeichnis
	
	
	# Und einen Webschnitt für dieses Crawl-Verzeichnis anlegen.
	warcFilenameBase=`echo $warcFilename | sed 's/\.warc\.gz$//'`
	json_body="{\"pid\":\"$NAMESPACE:$pid\",\"crawldir\":\"$zeitstempel\",\"warcFilenameBase\":\"$warcFilenameBase\"}"
	echo "curl $curlopts -XPOST -H \"Content-Type: application/json; charset=utf-8; Accept: application/json\" -d \"$json_body\" \"$BACKEND/webhooks/lavCrawlIngest\""
	resultat=`curl $curlopts -XPOST -u$REGAL_ADMIN:$REGAL_PASSWORD -H "Content-Type: application/json; charset=utf-8; Accept: application/json" -d "$json_body" "$BACKEND/webhooks/lavCrawlIngest"`
	# auch das hat funktioniert; ToDo: hier noch von dem Endpoint ein Resultat zurück geben lassen (im Format JSON), welches die erzeugte WS-PID enthält. Die PID aus dem Resultat ausparsen und hier ausgeben.
	echo $resultat
	echo
	printf "INFO: Ein Webschnitt zur pid %s, crawldir %s wurde angelegt.\n" $NAMESPACE:$pid $zeitstempel

	
	cd $olddir
	if [ -n "$pid" ]; then
		pid=$(($pid+1))
	fi
	echo
	
done < $csv_datei.UTF-8
echo
echo "Script $0 terminating regularly."

exit 0
