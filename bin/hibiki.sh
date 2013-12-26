#!/bin/sh -e
# hibiki.sh ver.0.5.6 (2013-02-13)
# require wget, perl, and mimms
#
# http://interstadial.wordpress.com/2013/06/02/record-rtsp-streaming/
# 2013/12/26
#
# from ruby to perl at 2013/12/26 by @xtetsuji

#set -o xtrace # for DEBUG

TMPFILE="/var/tmp/tmp.$$"
trap 'rm -f ${TMPFILE}' EXIT
 
if [ $# -eq 1 ]; then
    STR=$1
 
    # save asx file
    #wget -q -O - http://hibiki-radio.jp/description/${STR} | grep WMV | ruby -ruri -e 'puts URI.extract(ARGF.read, "http")' | head -1 | xargs wget -q -O ${TMPFILE}
    wget -q -O - http://hibiki-radio.jp/description/${STR} | \
        grep WMV | \
        perl -ne 'm{src\s*=\s*"(http:.*?)"}x and print "$1\n"' | \
        head -1 | \
        xargs wget -q -O ${TMPFILE}

    if [ -z ${TMPFILE} ]; then
        echo "download ERROR"
        exit 1
    fi
    TITLE=`perl -ne 'm{<title>(.*?)</title>} and print "$1\n";' ${TMPFILE}`
    WMVFILE=`perl -ne 'm{<Ref\s+href\s*=\s*"(.*?)"} and print "$1\n";' ${TMPFILE}`
    
    if test a"$TITLE" = a"" ; then
        echo "asx detection failed."
        exit 1
    fi
 
    mimms -r ${WMVFILE} "${TITLE}.asf"
    mimms -r ${WMVFILE} "${TITLE}.asf"
 
else
    echo "usage: `basename $0` STRING"
fi
