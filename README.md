# Migrate from Upstash Kafka Connectors
This project is a helper tool for users to migrate from Upstash Kafka Connectors.

## Before Migrating
This repository contains all the connector plugins, `docker-compose` and `.properties` file generator for migrating your Upstash Kafka Connectors. Throughout, `docker-compose` is used with the official Kafka image. So, install `docker` and `docker-compose`, if they are not already installed.

> Make sure that you are not producing any new messages to the connector topic, and all the messages in that topic are consumed. This way, you won't have to deal with partition offsets as well.

## Generate the Files
Run the following command to generate a `docker-compose.yaml` file and `.properties` files.
(For standalone connector config, you can pass `-c 1`, which will only create 1 container for the connector.)
```
chmod +x setup-connectors.sh
./setup-connectors.sh -b BOOTSTRAP_URL -u USERNAME -p PASSWORD -c 3
docker-compose up
```
Here, BOOTSTRAP_URL is the ENDPOINT given in the [Upstash Console](https://console.upstash.com/kafka).

## Make sure containers are up
You can see the list of supported connectors via:
```
curl localhost:8081/connector-plugins
curl localhost:8082/connector-plugins
curl localhost:8083/connector-plugins

... (Depending on how many containers you have)
```

## Migrate Your Configs
In order to migrate the connectors, head out to `https://console.upstash.com/kafka/<cluster-id>?tab=connectors`, and select `edit` on the connector you wish to migrate. There, you will see a JSON config. You can use that config with the REST API to start a connector on the container, shown in this repository.

## Test Setup with Aiven Http Connector
To verify that the connector setup works:
You can go to `https://requestcatcher.com/` and get yourself a subdomain.
Then, you can create a connector via the REST API:

```
 curl -d '{"name": "test-connector","config": {"connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector","topics": "<chosen topic name>","http.url": "https://<subdomain>.requestcatcher.com/test","http.authorization.type": "none","key.converter": "org.apache.kafka.connect.storage.StringConverter","value.converter": "org.apache.kafka.connect.storage.StringConverter"}}' -H "Content-Type: application/json" -X POST http://localhost:8081/connectors
```

> Make sure you have created a topic with name `<chosen topic name>`.

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


## Cleanup
After you have safely migrated the connector, feel free to delete the connector from the console. If you are using our [Terraform](https://registry.terraform.io/providers/upstash/upstash) or [Pulumi](https://www.pulumi.com/registry/packages/upstash/) providers, also destroy the resources from there.

If you want to tear down the docker containers, simply run `docker-compose down`.