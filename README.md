# Kafka Connect with Upstash Kafka

This guide helps you deploy Kafka Connect with Docker using Upstash Kafka as your Apache Kafka provider.

**Prerequisites**

* Ensure you have Docker and Docker Compose installed on your system.

## Configure Kafka Connect

This guide sets up Kafka Connect in distributed mode, allowing you to scale up on demand as needed.

**Generate Configuration Files**

1. Begin by generating the configuration files, `connect-distributed.properties` and `docker-compose.yaml`. Run the following command:

```bash
chmod +x setup-connectors.sh
./setup-connectors.sh -b UPSTASH_KAFKA_ENDPOINT -u UPSTASH_KAFKA_USERNAME -p UPSTASH_KAFKA_PASSWORD -c 1
```

2. Replace the placeholders with the corresponding values from your Upstash Kafka cluster page accessible at Upstash Console: [https://console.upstash.com/kafka](https://console.upstash.com/kafka):

* `UPSTASH_KAFKA_ENDPOINT`
* `UPSTASH_KAFKA_USERNAME`
* `UPSTASH_KAFKA_PASSWORD`

**Understanding `connect-distributed.properties`**

The `connect-distributed.properties` file contains configurations for the Kafka Connect framework itself. It includes important parameters that are documented within the file. You can further modify these parameters based on your specific needs. Refer to the : [Connect Distributed Config](https://github.com/apache/kafka/blob/4cb6806cb8f1cdbf9f47cb6521127fd3f49fa712/connect/runtime/src/main/java/org/apache/kafka/connect/runtime/distributed/DistributedConfig.java#L151) for a complete list of properties.

**Scaling Kafka Connect Processes**

To scale up the Kafka Connect processes, you can provide a value greater than 1 for the `-c` flag in the generation script. This will create a `docker-compose.yaml` file that can be used to launch multiple Docker containers, each running its own Kafka Connect process cooperatively.

**Connector Resources**

Sample configurations for some well-known connectors are provided in the `./connectors` directory. It's important to note that these are for illustrative purposes only and may become outdated. Ensure the JAR files for the connectors you require are placed in a directory within the `./connectors` directory.

## Start and Verify Kafka Connect

**Run Kafka Connect**

1. Use Docker Compose to start Kafka Connect:

```bash
docker-compose up
```

**Verify Connector Recognition**

2. You can verify that your connector is recognized and loaded by Kafka Connect using the [Rest API](#list-available-connector-plugins) as follows:

```bash
curl localhost:8081/connector-plugins
curl localhost:8082/connector-plugins
curl localhost:8083/connector-plugins

# ... (Depending on how many containers you have)
```

**Stopping Kafka Connect**

3. To stop the Docker containers, simply run:

```bash
docker-compose down
```

### Example Setup with Aiven Http Connector

**Verify Connector Functionality**

1. To verify if your connector setup works, visit [https://requestcatcher.com/](https://requestcatcher.com/) to obtain a subdomain.

2. Create a connector using the REST API:

```bash
curl -H "Content-Type: application/json" -X POST http://localhost:8081/connectors -d '{
  "name": "test-connector",
  "config": {
    "connector.class": "io.aiven.kafka.connect.http.HttpSinkConnector",
    "topics": "<chosen topic name>",
    "http.url": "https://<subdomain>.requestcatcher.com/test",
    "http.authorization.type": "none",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter"
  }
}'
```

**Important Note:** Ensure you've created a topic with the name `<chosen topic name>`.

3. Now, when you produce a message to the topic `<chosen topic name>`, you should be able to see the request captured at `https://<subdomain>.requestcatcher.com/test`. This confirms that your connector setup is functioning correctly.

### Kafka Connect REST API

The Kafka Connect REST API provides functionalities for managing Kafka Connect. Here are some common operations you can perform:

**List Available Connector Plugins**

```bash
curl localhost:8081/connector-plugins
```

This command retrieves a response listing all the available connector plugins recognized by Kafka Connect on that specific worker. The response will be in JSON format, containing details like class name, type, and version for each plugin.

**Example Response:**

```json
[
  {
    "class": "com.mongodb.kafka.connect.MongoSinkConnector",
    "type": "sink",
    "version": "1.10.0"
  },
  # ... (List of other connectors)
]
```

**List Created Connectors**

```bash
curl localhost:8081/connectors
```

This command returns a JSON response containing a list of all currently created connectors on that Kafka Connect worker. The response will include the names of the connectors.

**Example Response:**

```json
["connector-name"]
```

**Get Details of a Connector**

```bash
curl localhost:8081/connectors/<connector-name>
```

Replace `<connector-name>` with the actual name of the connector you want details for. This command retrieves a detailed JSON response about the specified connector, including its configuration, tasks, and type (source or sink).

**Example Response:**

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

**Create a Connector**

```bash
curl -d '{"name": "<name>","config": <config json>}' -H "Content-Type: application/json" -X POST http://localhost:8081/connectors
```

This command allows you to create a new connector using a JSON payload containing the connector's name and configuration.

For detailed information and additional functionalities, refer to Kafka Connect REST API documentation: [https://docs.confluent.io/platform/current/connect/references/restapi.html](https://docs.confluent.io/platform/current/connect/references/restapi.html)

## Migration Guide From Upstash Kafka Connect

If you were previously using Kafka Connect provided by Upstash, here's a guide to migrate to your own self-hosted Kafka Connect:

1. **Set Up Kafka Connect Framework**
  Follow the instructions in the [Kafka Connect with Upstash Kafka](#kafka-connect-with-upstash-kafka) section to set up the Kafka Connect framework. However, hold off on creating connectors at this point.

2. **Prepare for Connector Migration**
  * **Sync Connectors:** Ensure no new messages are being produced to the connector topic, and all existing messages within the topic have been consumed. Subsequently, pause the connector on the Upstash console. 
  * **Source Connectors:** Stop any traffic to your database before pausing the connector on the Upstash console.

3. **Migrate Connectors**
  Upstash provides a REST API and an "Export Config" button on the console to export your Kafka Connect configuration. You can then use this configuration directly to create connectors using the Kafka Connect [Rest API](#create-a-connector).
    * **Console:** On the Upstash console, navigate to the list of connectors and click the "Export Config" button for the desired connector to retrieve its configuration.
    * **REST API:** Obtain your `UPSTASH_KAFKA_REST_URL` from the Upstash cluster page accessible at Upstash Console: [https://console.upstash.com/kafka](https://console.upstash.com/kafka).
      * Retrieve all connector configurations:
      ```bash
      curl UPSTASH_KAFKA_REST_URL/connect/config -u UPSTASH_KAFKA_REST_USERNAME:UPSTASH_KAFKA_REST_PASSWORD
      ```
      * To get a config of a specific connector:
      ```
      curl UPSTASH_KAFKA_REST_URL/connect/config/CONNECTOR_NAME -u UPSTASH_KAFKA_REST_USERNAME:UPSTASH_KAFKA_REST_PASSWORD
      ```

4. **Finalize Migration**
  * After successfully migrating a connector, you can safely delete it from the Upstash console.
  * If you're using Upstash's [Terraform](https://registry.terraform.io/providers/upstash/upstash) or  [Pulumi](https://www.pulumi.com/registry/packages/upstash/) providers, you should also destroy the corresponding resources within those providers.

