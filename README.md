# E2E Process with Business Rules App on K8s POC

## Description

A quickstart project that shows E2E build, deployment of a business rules and processes kogito app

This example shows

* make use of DRL to define rules
* make use of business rules task in the process to evaluate rules
* containerize the app
* deploy it on Kubernetes using Helm


<p align="center"><img width=75% height=50% src="docs/images/process.png"></p>

* Diagram Properties (top)
<p align="center"><img src="docs/images/diagramProperties.png"></p>

* Diagram Properties (bottom)
<p align="center"><img src="docs/images/diagramProperties2.png"></p>

* Evaluate Person Business Rule (top)
<p align="center"><img src="docs/images/evaluatePersonBusinessRule.png"></p>

* Evaluate Person Business Rule (bottom)
<p align="center"><img src="docs/images/evaluatePersonBusinessRule2.png"></p>

* Evaluate Person Business Rule (Assignments)
<p align="center"><img src="docs/images/evaluatePersonBusinessRuleDataAssignments.png"></p>

* Exclusive Gateway
<p align="center"><img src="docs/images/exclusiveGateway.png"></p>

* Exclusive Gateway For Adult Connector
<p align="center"><img src="docs/images/exclusiveGatewayForAdult.png"></p>

* Exclusive Gateway For Children Connector
<p align="center"><img src="docs/images/exclusiveGatewayForChildren.png"></p>

* Special Handling for Children (top)
<p align="center"><img src="docs/images/specialHandlingForChildren.png"></p>

* Special Handling for Children (middle)
<p align="center"><img src="docs/images/specialHandlingForChildren2.png"></p>

* Special Handling for Children (bottom)
<p align="center"><img src="docs/images/specialHandlingForChildren3.png"></p>

* Special Handling for Children (Assignments)
<p align="center"><img src="docs/images/specialHandlingForChildrenAssignments.png"></p>


## Build and run

### Prerequisites

You will need:
  - Java 11+ installed
  - Environment variable JAVA_HOME set accordingly
  - Maven 3.5.0+ installed
  - Docker Desktop (comes installed with K8s cluster)
  - Helm

### Package the App

```
mvn clean package -Denforcer.skip=true
```

### Containerize the App

```
docker build --tag=shivajifordocker/process-business-rules-springboot:1.16.0 .
docker push shivajifordocker/process-business-rules-springboot:1.16.0
```

### Deploy the App

```
cd charts
helm install process-business-rules-springboot process-business-rules-springboot
kubectl --namespace default port-forward $POD_NAME 8080:8080
```

### Deploy Monitoring Tools

```
kubectl create namespace monitoring
helm install prometheus prometheus --namespace monitoring
helm install grafana grafana --namespace monitoring
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
kubectl --namespace monitoring port-forward deploy/grafana 3000
```

### OpenAPI (Swagger) documentation
[Specification at swagger.io](https://swagger.io/docs/specification/about/)

You can take a look at the [OpenAPI definition](http://localhost:8080/v3/api-docs) - automatically generated and included in this service - to determine all available operations exposed by this service. For easy readability you can visualize the OpenAPI definition file using a UI tool like for example available [Swagger UI](https://editor.swagger.io).

In addition, various clients to interact with this service can be easily generated using this OpenAPI definition.


## Example Usage

Once the service is up and running we can invoke the REST endpoints and examine the logic.

### Submit a request

To make use of this application it is as simple as putting a sending request to `http://localhost:8080/persons`  with appropriate contents. See the following two cases:

#### Adult person

Given data:

```json
{
  "person" : {
    "name" : "john",
    "age" : 20
  }
}

```

Submit the JSON object from above:

```
curl -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{"person" : {"name" : "john", "age" : 20}}' http://localhost:8080/persons
```

After the Curl command you should see a similar console log

```
{
    "id":"fd4f629d-6822-4ca2-a8a6-a74f5f81e83d",
    "person":{
        "name":"john",
        "age":20,
        "adult":true
    }
}
```

Because the person is evaluated as an adult, no outstanding tasks should be here for given person.

We can verify there is no task running for Children Handling using following command:

```
curl http://localhost:8080/persons/{uuid}/tasks
```
where uuid is the id returned in the previous step.

#### A Child

Given data:

```json
{
    "person" : {
        "name" : "john",
        "age" : 5
    }
}
```

Submit the JSON object from above:

```sh
curl -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{"person" : {"name" : "john", "age" : 5}}' http://localhost:8080/persons
```

After the Curl command you should see a similar console log

```json
{
    "id":"c59054b9-aa1d-4771-bc5e-40f8b32d3ff5",
    "person":{
        "name":"john",
        "age":5,
        "adult":false
    }
}
```

Because the person is not evaluated as an adult, there should be outstanding tasks for given person.

To verify there is a running task for Children

```sh
curl http://localhost:8080/persons/{uuid}/tasks
```
where uuid is the id returned from the preivous step.

Should return something like

```json
[{"id":"c59054b9-aa1d-4771-bc5e-40f8b32d3ff5","name":"ChildrenHandling".....}]
```


Then to see the Task created perform the following command

```sh
curl http://localhost:8080/persons/{uuid}/ChildrenHandling/{tuuid}
```

where uuid is persons id and tuuid is task id.

It should return something similar to

```json
{
    "person":{
        "name":"john",
        "age":5,
        "adult":false
    },
    "id":"c59054b9-aa1d-4771-bc5e-40f8b32d3ff5",
    "name":"ChildrenHandling"
}
```

Then we can complete the task and validate child with

```sh
curl -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{}' http://localhost:8080/persons/{uuid}/ChildrenHandling/{tuuid}
```

Where uuid is persons id and tuuid is task id

Should return something similar to

```json
{
    "id":"09f98756-b273-4ceb-9308-fae7cc423904",
    "person":{
        "name":"john",
        "age":5,
        "adult":false
    }
}
```
and there should be no outstanding task for the person anymore.
