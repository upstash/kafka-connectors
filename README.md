# Migrate from Upstash Kafka Connectors

Run the following command to generate a docker-compose.yaml file and connector properties.
(For standalone, single server, connector config, you can pass `-c 1`, which will only create 1 replica for the connector.)
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


## Test Setup with Aiven Http Connector
To verify that the connector setup works:
You can go to `https://requestcatcher.com/` and get yourself a subdomain.
Then, you can create a connector via the REST API:

```
 curl -d '{"name": "test-connector","config": {"connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector","topics": "<chosen topic name>","http.url": "https://<subdomain>.requestcatcher.com/test","http.authorization.type": "none","key.converter": "org.apache.kafka.connect.storage.StringConverter","value.converter": "org.apache.kafka.connect.storage.StringConverter"}}' -H "Content-Type: application/json" -X POST http://localhost:8081/connectors
```

>>> Make sure you have created a topic with name `<chosen topic name>`.

Now, when you produce a message to topic `<chosen topic name>`, you should be able to see the request caught at `https://<subdomain>.requestcatcher.com/test`.

With this, you can verify that the connector setup works.

## Connector Rest API
You can do many operations on kafka-connect, through the REST API provided. Such examples are:

```bash
# List available connector plugins
curl localhost:8081/connector-plugins
>>> 
[{"class":"com.mongodb.kafka.connect.MongoSinkConnector","type":"sink","version":"1.10.0"},{"class":"com.snowflake.kafka.connector.SnowflakeSinkConnector","type":"sink","version":"1.9.1"},{"class":"com.wepay.kafka.connect.bigquery.BigQuerySinkConnector","type":"sink","version":"unknown"},{"class":"io.aiven.connect.jdbc.JdbcSinkConnector","type":"sink","version":"6.8.0"},{"class":"io.aiven.kafka.connect.http.HttpSinkConnector","type":"sink","version":"0.6.0"},{"class":"io.aiven.kafka.connect.opensearch.OpensearchSinkConnector","type":"sink","version":"3.0.0"},{"class":"io.aiven.kafka.connect.s3.AivenKafkaConnectS3SinkConnector","type":"sink","version":"2.12.1"},{"class":"com.mongodb.kafka.connect.MongoSourceConnector","type":"source","version":"1.10.0"},{"class":"io.aiven.connect.jdbc.JdbcSourceConnector","type":"source","version":"6.8.0"},{"class":"io.debezium.connector.mongodb.MongoDbConnector","type":"source","version":"2.2.1.Final"},{"class":"io.debezium.connector.mysql.MySqlConnector","type":"source","version":"1.9.7.Final"},{"class":"io.debezium.connector.postgresql.PostgresConnector","type":"source","version":"1.9.7.Final"},{"class":"org.apache.kafka.connect.mirror.MirrorCheckpointConnector","type":"source","version":"3.6.1"},{"class":"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector","type":"source","version":"3.6.1"},{"class":"org.apache.kafka.connect.mirror.MirrorSourceConnector","type":"source","version":"3.6.1"}]

# List created connectors
curl localhost:8081/connectors
>>>
["connector-name"]

# Get details of a connector
curl localhost:8081/connectors/<connector-name>
>>>
{"name":"connector-name","config":{"connector.class":"io.aiven.kafka.connect.http.HttpSinkConnector","http.authorization.type":"none","topics":"test","name":"connector-name","http.url":"https://<subdomain>.requestcatcher.com/test","value.converter":"org.apache.kafka.connect.storage.StringConverter","key.converter":"org.apache.kafka.connect.storage.StringConverter"},"tasks":[{"connector":"connector-name","task":0}],"type":"sink"}


# Create a connector
curl -d '{"name": "<name>","config": <config json>}' -H "Content-Type: application/json" -X POST http://localhost:8081/connectors
>>>
{"name":"connector-name","config":{"connector.class":"io.aiven.kafka.connect.http.HttpSinkConnector","topics":"test","http.url":"https://<subdomain>.requestcatcher.com/test","http.authorization.type":"none","key.converter":"org.apache.kafka.connect.storage.StringConverter","value.converter":"org.apache.kafka.connect.storage.StringConverter","name":"connector-name"},"tasks":[],"type":"sink"}
```

For more details, you can have a look at this [API documentation](https://docs.confluent.io/platform/current/connect/references/restapi.html)
