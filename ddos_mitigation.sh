#!/bin/bash

block(){
    timeout 1 sudo tcpdump -n -i enp0s3 dst port 27015 -c 100 -l >> /root/ddoserip
    tcpdump -n -i enp0s3 -w 0001.pcap dst port 27015 -c 100 -l
    ip="/root/playersips.log"
    for i in $(cat $ip); do
        echo "oci network nsg rules add --nsg-id ocid1.networksecuritygroup --security-rules '[{\"direction\": \"INGRESS\", \"is-stateless\": \"true\", \"source\": \"$i\", \"protocol\": \"17\", \"udpOptions\": {\"destinationPortRange\": {\"max\": 27015, \"min\": 27015}}}]'" >> rules.sh
    done
    chmod +x /root/rules.sh
    sh /root/rules.sh
    oci network vnic update --vnic-id ocid1.vnic --nsg-ids '["ocid1.networksecuritygroup"]' --force
    echo "BLOCK EXECUTED" >> /root/ddos.log
}

flush(){
    oci network vnic update --vnic-id ocid1.vnic --nsg-ids '["ocid1.networksecuritygroup"]' --force
    echo "FLUSH EXECUTED" >> /root/ddos.log
    rm -rf /root/rules.sh
}

while(true)
do
        IF=eth0
        R1=`cat /sys/class/net/$IF/statistics/rx_bytes`
        T1=`cat /sys/class/net/$IF/statistics/tx_bytes`
        sleep 1
        R2=`cat /sys/class/net/$IF/statistics/rx_bytes`
        T2=`cat /sys/class/net/$IF/statistics/tx_bytes`
        TBPS=`expr $T2 - $T1`
        RBPS=`expr $R2 - $R1`
        TKBPS=`expr $TBPS / 1024`
        RKBPS=`expr $RBPS / 1024`
        ddos=`expr $TKBPS + $RKBPS`
        time=$(date +"%d.%m.%Y - %H:%M:%S")
        if [ "$ddos" -le 6000 ]; then
                continue
        else
            block
            echo "$ddos : Incoming at $time [ BLOCKED ]" >> /root/ddos.log
            sleep 310
            flush
            continue
        fi
done