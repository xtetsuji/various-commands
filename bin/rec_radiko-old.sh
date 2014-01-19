#!/bin/sh
# download at 2011/03/19
# from https://gist.github.com/875864

playerurl=http://radiko.jp/player/swf/player_2.0.1.00.swf
playerfile=./player.swf
keyfile=./authkey.png
user_agent="Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)"

if [ $# -eq 1 ]; then
  channel=$1
  output=./$1.flv
elif [ $# -eq 2 ]; then
  channel=$1
  output=$2
elif [ $# -eq 3 ]; then
  channel=$1
  output=$2
  seconds=$3
else
  echo "usage : $0 channel_name [outputfile [rec_seconds]]"
  exit 1
fi

#
# get player
#
if [ ! -f $playerfile ]; then
  wget \
    --user-agent="$user_agent" \
    -q \
    -O $playerfile \
    $playerurl

  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

#
# get keydata (need swftools)
#
if [ ! -f $keyfile ]; then
  swfextract -b 5 $playerfile -o $keyfile

  if [ ! -f $keyfile ]; then
    echo "failed get keydata"
    exit 1
  fi
fi

if [ -f auth1_fms ]; then
  rm -f auth1_fms
fi

#
# access auth1_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --user-agent="$user_agent" \
     --post-data='\r\n' \
     --no-check-certificate \
     --save-headers \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  exit 1
fi

#
# get partial key
#
authtoken=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)'`
offset=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)'`
length=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)'`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f auth1_fms

if [ -f auth2_fms ]; then
  rm -f auth2_fms
fi

#
# access auth2_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-Authtoken: ${authtoken}" \
     --header="X-Radiko-Partialkey: ${partialkey}" \
     --user-agent="$user_agent" \
     --post-data='\r\n' \
     --no-check-certificate \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f auth2_fms ]; then
  echo "failed auth2 process"
  exit 1
fi

echo "authentication success"

areaid=`cat auth2_fms | perl -ne 'print $1 if(/^([^,]+),/i)'`
echo "areaid: $areaid"

rm -f auth2_fms

#
# rtmpdump
#
if [ -n "$seconds" ]; then
  seconds_param="-B $seconds"
else
  seconds_param=""
fi
quiet=--quiet

rtmpdump -v \
         $quiet \
         -r "rtmpe://radiko.smartstream.ne.jp" \
         --playpath "simul-stream" \
         --app "${channel}/_defInst_" \
         -W $playerurl \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --flv $output \
         $seconds_param \
         ;

#
# ffmpeg (add by ogata at 2011/04/03)
#
ffmpeg -i $output -acodec copy ${output%.flv}.aac >/dev/null 2>&1
