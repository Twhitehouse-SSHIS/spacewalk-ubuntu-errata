#!/bin/bash

### Processes Ubuntu Errata and imports them to Spacewalk
## Edit variables in errata-import.py first ##

# Get the base path for the script #
BASE_PATH="$(echo ${0} | sed 's/errata-sync.sh//')"

# Make sure we have English locale
export LC_TIME="en_US.utf8"

# Obtains the current date and year.
DATE=`date +"%Y-%B"`

# Cleanup before download
cd ${BASE_PATH}
mkdir -p errata
rm -rf errata/*.txt
rm -f ubuntu-errata.xml

# Do we want to pull all errata since the beginning
echo Option 1 contains $1
if [ "$1" = "all" ]; then
    START_YEAR=12            #Change to last 2 digits of desired starting year
    # Grab info about current month/year
    CURR_YEAR=`date +"%y"`
    CURR_MONTH=`date +"%B"`
    # Helper funciton
    function logger() {
        echo "INFO : $@"
    }
    # Fetch previous months errata
    for y in $(eval echo "{${START_YEAR}..${CURR_YEAR}}"); do
        for m in January February March April May June July August September October November December; do
            if [ "$CURR_MONTH" = $m ] && [ "$CURR_YEAR" = $y ]; then
                logger "Current month and year reached, use 'spacewalk-errata.sh' to import this month's errata after current process finishes."
                break
            else
                # Download and extract archives from USN
                DATE="20${y}-${m}"
                logger "Downloading errata from $m 20$y..."
                curl --progress-bar https://lists.ubuntu.com/archives/ubuntu-security-announce/$DATE.txt.gz > ${BASE_PATH}errata/$DATE.txt.gz
                gunzip -f ${BASE_PATH}errata/$DATE.txt.gz
            fi
        done
    done
    # Combine logs into one file for import
    cat ${BASE_PATH}errata/*.txt > ${BASE_PATH}errata/old.txt
    # Processes and imports the errata
    logger "Converting archives into XML for processing..."
    cd ${BASE_PATH} && \
    ${BASE_PATH}parseUbuntu.py ${BASE_PATH}errata/old.txt
    logger "Starting Errata importing..."
else
# Download Latest Errata
    curl https://lists.ubuntu.com/archives/ubuntu-security-announce/$DATE.txt.gz > ${BASE_PATH}errata/$DATE.txt.gz
    gunzip -f errata/$DATE.txt.gz
fi

# Processes and imports the errata.
${BASE_PATH}parseUbuntu.py errata/$DATE.txt
${BASE_PATH}errata-import.py
