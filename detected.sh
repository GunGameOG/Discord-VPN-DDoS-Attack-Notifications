echo -e "Discord DDoS alerts, coded by GunGameOG and maintained by GalaxyNodes."
echo
echo -e "033[97mPackets/s \033[36m{}\n\033[97mBytes/s \033[36m{}\n\033[97mKbp/s \033[36m{}\n\033[97mGbp/s \033[36m{}\n\033[97mMbp/s \033[36m{}"
interface=eth0
dumpdir=/root/dumps
url='https://discord.com/api/webhooks/1007477321931968592/d1fhY9fukvK3IUEWCr7VE_1e2Fm6QBkB6Ugg8vEP7lINZ_UpQf0vgZRwPJ6_eAJ3KZ_8' ## Change this to your Webhook URL
while /bin/true; do
  old_bs=`grep $interface: /proc/net/dev | cut -d :  -f2 | awk '{ print $1 }'`
  
  old_ps=`grep $interface: /proc/net/dev | cut -d :  -f2 | awk '{ print $2 }'`
  sleep 1
  new_bs=`grep $interface: /proc/net/dev | cut -d :  -f2 | awk '{ print $1 }'`

  new_ps=`grep $interface: /proc/net/dev | cut -d :  -f2 | awk '{ print $2 }'`
  ##Defining Packets/s
  pps=$(( $new_ps - $old_ps ))
  ##Defining Bytes/s
  byte=$(( $new_bs - $old_bs ))

  gigs=$(( $byte/1024 ** 3 ))
  mbps=$(( $byte/1024 ** 2 ))
  kbps=$(( $byte/1024 ** 1 ))

  echo -ne "\$new_ps packets/s\033[0K"
  tshark -n -s0 -c 300 -w $dumpdir/Packets.pcap
  echo "`date` Detecting Attack Packets."
  sleep 300
  if [ $new_ps -gt 100000 ]; then ## Attack alert will display after incoming traffic reach 30000 PPS
    echo " Attack Detected Monitoring Incoming Traffic"
    curl -H "Content-Type: application/json" -X POST -d '{
      "embeds": [{
      	"inline": false,
        "title": "Attack detected",
        "username": "DDoS Alerts",
        "color": 15158332,
         "thumbnail": {
          "url": "https://i.imgur.com/ddzU7Sv.gif"
        },
         "footer": {
            "text": "Our system is attempting to mitigate the attack and automatic packet dumping has been activated.",
            "icon_url": "https://media.discordapp.net/attachments/729400089512247307/862308586943676426/logo_web.png"
          },
    
        "description": "Detection of an attack",
         "fields": [
      {
        "name": "Node",
        "value": "Game Node",
        "inline": false
      },
      {
        "name": "**Incoming bandwith**",
        "value": "'$new_bs' Megabytes Per Second",
        "inline": false
      },
      {
        "name": "**Incoming Packets**",
        "value": " '$new_ps' Packets Per Second ",
        "inline": false
      }
    ]
      }]
    }' $url
    echo "Paused for."
    sleep 300
    tshark -r capture.pcap -T fields -e frame.protocols -e tcp.dstport -E separator=, -E quote=d
    ## echo "Traffic Attack Packets Scrubbed"
    if grep -Fxq "NTP" capture.pcap; then
     method=NTP 
    else 
     method=Unkown
    fi
    if grep -Fxq "TCP" capture.pcap; then
     $method=TCP
    else
     $method=Unkown
    fi
    if grep -Fxq "UDP" capture.pcap; then
     $method=UDP
    else
     $method=Unkown
    fi
    echo -ne "\$old_bs megabytes/s\033[97"
    curl -H "Content-Type: application/json" -X POST -d '{
      "embeds": [{
      	"inline": false,
        "title": "Attack Stopped",
        "username": "DDoS Alerts",
        "color": 3066993,
         "thumbnail": {
          "url": "https://i.imgur.com/M5oKPub.gif"
        },
         "footer": {
            "text": "Our system has mitigated the attack and automatic packet dumping has been deactivated.",
            "icon_url": "https://media.discordapp.net/attachments/729400089512247307/862308586943676426/logo_web.png"
          },    
          
        "description": "End of attack",
         "fields": [
      {
        "name": "**Node**",
        "value": "Game Node",
        "inline": false
      },
      {
        "name": "**Method**",
        "value": "'$method', if it shows Unkown, it means we are still adding more methods into the script and requires manual checking.",
        "inline": false
      },
      {
        "name": "**Packets per second during the attack**",
        "value": "'$old_ps' packets per second",
        "inline": false
      },
      {
        "name": "**Megabytes per second during the attack**",
        "value": "'$old_bs' Mbps",
        "inline": false
      }
    ]
      }]
    }' $url
  fi
done
