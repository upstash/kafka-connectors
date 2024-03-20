# Migrate from Upstash Kafka Connectors

Run the following command to generate a docker-compose.yaml file and connector properties.
```
chmod +x setup-connectors.sh
./setup-connectors.sh -b BOOTSTRAP_URL -u USERNAME -p PASSWORD -c 3
docker-compose up
```

## See list of connectors
```
curl localhost:8081/connector-plugins
curl localhost:8082/connector-plugins
curl localhost:8083/connector-plugins

... (Depending on how many replicas you have)
```