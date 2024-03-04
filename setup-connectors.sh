#!/bin/bash
set -e
set -o pipefail

url=""
username=""
password=""
scale=""

usage() {
    echo "Usage: $0 -b <URL> -u <USERNAME> -p <PASSWORD> -c <SCALE_COUNT>"
    exit 1
}

# Parse command line options
while getopts ":b:u:p:c:" opt; do
    case ${opt} in
        b )
            url=$OPTARG
            ;;
        u )
            username=$OPTARG
            ;;
        p )
            password=$OPTARG
            ;;
        c )
            scale=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$url" ] || [ -z "$url" ] || [ -z "$password" ] || [ -z "$scale" ]; then
    echo "ENDPOINT, USERNAME, PASSWORD, SCALE_COUNT are required."
    usage
fi

rm -f connect-distributed-*
rm -f docker-compose.yaml

cat > docker-compose.yaml <<EOF
version: "2"
services:
EOF

for ((i=1; i<=$scale; i++)); do
    cat >> docker-compose.yaml <<EOF
  kafka-connect-$i:
    image: docker.io/bitnami/kafka:3.6
    ports:
    - '808${i}:8083'
    environment:
      BITNAMI_DEBUG: true
    volumes:
    - \$PWD/connect-distributed-$i.properties:/tmp/connect-distributed-$i.properties
    - \$PWD/connectors:/tmp/connectors
    command: /opt/bitnami/kafka/bin/connect-distributed.sh /tmp/connect-distributed-$i.properties

EOF
done

for ((j=1; j<=$scale; j++)); do
    config=$(<template-connect-distributed.properties)
    config=${config//#ENDPOINT#/$url}
    config=${config//#USERNAME#/$username}
    config=${config//#PASSWORD#/$password}
    config=${config//#ID#/$j}
    echo "$config">"connect-distributed-$j.properties"
done
