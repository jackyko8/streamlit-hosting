#!/bin/bash

# The zipped Streamlit app is downloaded from S3 and extracted to $rundir.
# A SHA256 hash of the zipped app is downloaded from S3 and stored in $rundir.
# The S3 bucket and key are defined in $rundir/app.conf .

# If the hash of the downloaded zipped app is different from the stored hash,
# the app will be updated into $appdir, then the old zip file will be backed up,
# and the new hash will be stored in $rundir.

logfile=/var/log/streamlit-app.log
appdir=/opt/streamlit-app

homedir=~
rundir=$homedir/streamlit-app
zipfile=$rundir/app.zip
zipbackup=$zipfile.bak
hashfile=$rundir/app.zip.sha256

if [ ! -d $rundir ]; then
    echo "Run directory not found."
    exit 1
fi

source $rundir/app.conf
s3fullpath=s3://${S3BucketName}/${S3Key}

function init {
    echo "=== $(date) ==="
}

function check_update {
    echo "Checking for updates..."
    mv $zipfile $zipbackup
    aws s3 cp $s3fullpath $zipfile
    newhash=$(sha256sum $zipfile | cut -d' ' -f1)
    if [ -f $hashfile ]; then
        echo "Hash file found."
        oldhash=$(cat $hashfile)
        if [ $newhash == $oldhash ]; then
            echo "No updates found."
            return 1
        else
            echo "Updates found."
            echo $newhash > $hashfile
            return 0
        fi
    else
        echo "Hash file not found."
        echo $newhash > $hashfile
        return 0
    fi
}

function update_app {
    # The current script may be updated too but that is fine.
    # It will be used next time.
    echo "Updating app..."
    rm -rf $appdir/*
    unzip -o $zipfile -d $appdir
    # Itself may be updated.
    chmod +x $0
    cd $appdir
    export TMPDIR=$homedir/tmp
    mkdir -p $TMPDIR
    pip3 install -r requirements.txt
    echo "App updated."
}

function start_streamlit {
    port=${1:-${AppPort:-8501}}
    streamlit=$(which streamlit)
    if [ -z "$streamlit" ]; then
        echo "Streamlit not found. Please install Streamlit."
        exit 1
    fi
    echo "App starting on port $port"
    $streamlit run $appdir/app.py --server.port $port
    echo "App ended"
}


# Main
(
    source $homedir/.bashrc
    init
    if check_update; then
        update_app
    fi
    start_streamlit
) >> $logfile 2>&1
