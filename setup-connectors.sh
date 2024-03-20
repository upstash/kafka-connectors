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
    echo "URL, USERNAME, PASSWORD, SCALE_COUNT are required."
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
    - $PWD/connect-distributed-$i.properties:/tmp/connect-distributed-$i.properties
    - $PWD/connectors:/tmp/connectors
    command: /opt/bitnami/kafka/bin/connect-distributed.sh /tmp/connect-distributed-$i.properties

EOF
done

for ((j=1; j<=$scale; j++)); do
    cat > connect-distributed-$j.properties <<EOF
bootstrap.servers=$url
config.storage.replication.factor=1
config.storage.topic=connect-configs
consumer.sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="$username" password="$password";
consumer.sasl.mechanism=SCRAM-SHA-256
consumer.security.protocol=SASL_SSL
consumer.ssl.endpoint.identification.algorithm=
group.id=connect-cluster
key.converter.schemas.enable=true
key.converter=org.apache.kafka.connect.json.JsonConverter
offset.flush.interval.ms=10000
offset.storage.replication.factor=1
offset.storage.topic=connect-offsets
plugin.path=/tmp/connectors
producer.sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="$username" password="$password";
producer.sasl.mechanism=SCRAM-SHA-256
producer.security.protocol=SASL_SSL
producer.ssl.endpoint.identification.algorithm=
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="$username"  password="$password";
sasl.mechanism=SCRAM-SHA-256
security.protocol=SASL_SSL
ssl.endpoint.identification.algorithm=
status.storage.replication.factor=1
status.storage.topic=connect-status
value.converter.schemas.enable=true
value.converter=org.apache.kafka.connect.json.JsonConverter
rest.advertised.host.name=kafka-connect-$j
EOF
done