# Migrate from Upstash Kafka Connectors
This project is a helper tool for users to migrate from Upstash Kafka Connect to self-hosted Kafka Connect.

## Before Migrating
This repository contains all the connector plugins, `docker-compose`, and `.properties` file generators for migrating your Upstash Kafka Connectors. Throughout, `docker-compose` is used with the official Kafka image. So, install `docker` and `docker-compose`, if they are not already installed.

> Make sure that you are not producing any new messages to the connector topic, and that all the messages in that topic are consumed. And don't forget to pause the connector on the Upstash console before trying.

## Generate the Files
Run the following command to generate a `docker-compose.yaml` file and `.properties` files.

```
chmod +x setup-connectors.sh
./setup-connectors.sh -b UPSTASH_KAFKA_ENDPOINT -u UPSTASH_KAFKA_USERNAME -p UPSTASH_KAFKA_PASSWORD -c 1
docker-compose up
```

You can copy the following from the related cluster page at [Upstash Console](https://console.upstash.com/kafka).
- UPSTASH_KAFKA_ENDPOINT
- UPSTASH_KAFKA_USERNAME
- UPSTASH_KAFKA_PASSWORD

To scale up the connect processes, you can pass a greater value than 1 for `-c`. This will create multiple docker images each running its own Kafka Connect process cooperatively.

## Make sure containers are up
You can see the list of supported connectors via:

```bash
curl localhost:8081/connector-plugins
curl localhost:8082/connector-plugins
curl localhost:8083/connector-plugins

# ... (Depending on how many containers you have)
```

## Migrate Your Configs
To migrate the connectors, head out to `https://console.upstash.com/kafka/<cluster-id>?tab=connectors`, and select `edit` on the connector you wish to migrate. There, you will see a JSON config. You can use that config with the REST API to start a connector on the container, shown in this repository.

## Example Setup with Aiven Http Connector

To verify that the connector setup works:
You can go to `https://requestcatcher.com/` and get yourself a subdomain.
Then, you can create a connector via the REST API:

```bash
 curl -H "Content-Type: application/json" -X POST http://localhost:8081/connectors -d '{
    "name": "test-connector",
    "config": {
        "connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector",
        "topics": "<chosen topic name>",
        "http.url": "https://<subdomain>.requestcatcher.com/test",
        "http.authorization.type": "none","key.converter": 
        "org.apache.kafka.connect.storage.StringConverter",
        "value.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
}' 
```

> Make sure you have created a topic with name `<chosen topic name>`.

Now, when you produce a message to a topic `<chosen topic name>`, you should be able to see the request caught at `https://<subdomain>.requestcatcher.com/test`.

With this, you can verify that the connector setup works.

## Connector Rest API
You can do many operations on kafka-connect, through the REST API provided. Such examples are:

### List available connector plugins

```bash
curl localhost:8081/connector-plugins
```
Response:
```json
[
  {
    "class": "com.mongodb.kafka.connect.MongoSinkConnector",
    "type": "sink",
    "version": "1.10.0"
  },
  {
    "class": "com.snowflake.kafka.connector.SnowflakeSinkConnector",
    "type": "sink",
    "version": "1.9.1"
  },
  {
    "class": "com.wepay.kafka.connect.bigquery.BigQuerySinkConnector",
    "type": "sink",
    "version": "unknown"
  },
  {
    "class": "io.aiven.connect.jdbc.JdbcSinkConnector",
    "type": "sink",
    "version": "6.8.0"
  },
  {
    "class": "io.aiven.kafka.connect.http.HttpSinkConnector",
    "type": "sink",
    "version": "0.6.0"
  },
  {
    "class": "io.aiven.kafka.connect.opensearch.OpensearchSinkConnector",
    "type": "sink",
    "version": "3.0.0"
  },
  {
    "class": "io.aiven.kafka.connect.s3.AivenKafkaConnectS3SinkConnector",
    "type": "sink",
    "version": "2.12.1"
  },
  {
    "class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "type": "source",
    "version": "1.10.0"
  },
  {
    "class": "io.aiven.connect.jdbc.JdbcSourceConnector",
    "type": "source",
    "version": "6.8.0"
  },
  {
    "class": "io.debezium.connector.mongodb.MongoDbConnector",
    "type": "source",
    "version": "2.2.1.Final"
  },
  {
    "class": "io.debezium.connector.mysql.MySqlConnector",
    "type": "source",
    "version": "1.9.7.Final"
  },
  {
    "class": "io.debezium.connector.postgresql.PostgresConnector",
    "type": "source",
    "version": "1.9.7.Final"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorCheckpointConnector",
    "type": "source",
    "version": "3.6.1"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorHeartbeatConnector",
    "type": "source",
    "version": "3.6.1"
  },
  {
    "class": "org.apache.kafka.connect.mirror.MirrorSourceConnector",
    "type": "source",
    "version": "3.6.1"
  }
]
```

### List created connectors

```bash
curl localhost:8081/connectors
```
Response:
```json
["connector-name"]
```

#### Get details of a connector

```bash
curl localhost:8081/connectors/<connector-name>
```
Response:
```json
{
  "name": "connector-name",
  "config": {
    "connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector",
    "http.authorization.type": "none",
    "topics": "test",
    "name": "connector-name",
    "http.url": "https://<subdomain>.requestcatcher.com/test",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter"
  },
  "tasks": [
    {
      "connector": "connector-name",
      "task": 0
    }
  ],
  "type": "sink"
}
```

### Create a connector

```bash
curl -d '{"name": "<name>","config": <config json>}' -H "Content-Type: application/json" -X POST http://localhost:8081/connectors
```
Response:
```json
{
  "name": "connector-name",
  "config": {
    "connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector",
    "topics": "test",
    "http.url": "https://<subdomain>.requestcatcher.com/test",
    "http.authorization.type": "none",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "name": "connector-name"
  },
  "tasks": [],
  "type": "sink"
}
```

For more details, you can have a look at this [API documentation](https://docs.confluent.io/platform/current/connect/references/restapi.html)

## Cleanup
After you have safely migrated the connector, feel free to delete the connector from the console. If you are using our [Terraform](https://registry.terraform.io/providers/upstash/upstash) or [Pulumi](https://www.pulumi.com/registry/packages/upstash/) providers, also destroy the resources from there.

If you want to tear down the docker containers, simply run `docker-compose down`.
