# client-fhir-testing
Tool to test a client's conformance with a FHIR implementation guide.


### Quick Run:
```sh
ruby start-proxy.rb
```
<br/>

## Setup:
The client fhir testing tool is in the form of a proxy application that 
will record transactions between a fhir client and a fhir server.  These 
HTTP transactions are recorded in a database where validation tests 
can later be run against them. The requests 
can also be replayed to mimic client or server endpoints.  <br />

For development purposes we will use the Inferno tool to act as a FHIR 
client and a public endpoint will be used as a FHIR server.

### Install & Run Inferno (Client)
1.  Download & install inferno using Docker directions: <br />
https://github.com/onc-healthit/inferno#installation-and-deployment

2.  Make sure docker desktop app is running

3.  Run 
```sh
docker-compose up
```

4.  open http://localhost:4567/


### Run Proxy
1.  Download this github repo
```sh
git clone https://github.com/inferno-community/client-fhir-testing.git
cd client-fhir-testing
```
2.  Run proxy

The following will read options from `filename`.  If `filename` does 
not exist, 
one with default options will be created for you.  If `filename` is left unspecified, 
`proxy.yml` will be used by default.

It is important to set the `backend` 
config option as this is the destination the proxy forwards to.
```sh
ruby start-proxy.rb [filename]
```

Alternatively, you can start the proxy via the rackup process and specify the 
backend as an environment variable.

```sh
FHIR_PROXY_BACKEND="https://r4.smarthealthit.org" rackup config.ru -p 9292 -o 0.0.0.0
```

### Run Inferno tests
We use inferno as our client but you can use any client/server interactions 
in this step. Note that the docker URL listed below resolves to the docker 
host machine on which the proxy is running.  Using localhost would refer 
to the docker instance and not the host itself.  <br />

1.  On the Inferno homepage, under "Start Testing", select "US Core v3.1.0", 
and put in the address of the proxy service `http://host.docker.internal:9292`

2.  Run tests, check the database for logged HTTP transactions.

## Run Validator in command line
The validator is developed based on the [US Core Client CapabilityStatement](https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-client.htm). 
The [client CapabilityStatement JSON file](resources/CapabilityStatement-us-core-client.json) was parsed into three tables, [interaction](resources/CapabilityStatement_interaction.csv), 
[searchParam](resources/CapabilitySatement_searchParam.csv), and [search_criteria](resources/CapabilitySatement_search_criteria.csv).
Capabilities rules from the three tables were used to validate the client requests.

We created a [collection of Postman requests](test/fhir-client-test.postman_collection.json) to simulate a client test.
The tool [newman](https://www.npmjs.com/package/newman) can be used to send the collection of requests to the proxy server.

1. To start the proxy server locally with the port 9292.
```sh
ruby start-proxy.rb
```

2. To send the requests with [newman](https://www.npmjs.com/package/newman) under the test directory.
```sh
cd test
newman run fhir-client-test.postman_collection.json
```

3. To run validator for the collection of requests.
```sh
ruby ../test-validator.rb
```
A `checklist.csv` report will be generated and also a `check_list` table created in the database.
Here are the description of the report.

| column | description  |
|---|---|
|id|serial number|
|resource|FHIR resource / action|
|request_type|code from the [interaction table](resources/CapabilityStatement_interaction.csv): read / vread / update / create / search-type|
|search_param|Array of search parameters. nil if not 'search-type'.|
|search_valid|boolean, whether search is valid (parameter in SHALL list and response status is 200). The SHALL list can be found in the [searchParam](resources/CapabilitySatement_searchParam.csv) table.|
|search_combination|1 parameter => nil; >1 parameters & find in the SHALL list => SHALL combinations; >1 parameters & not in the SHALL list => []. The combination list can be found in the [search_criteria](resources/CapabilitySatement_search_criteria.csv) table.|
|search_type|Array of boolean. whether each search value is valid for its data type. nil if not 'search-type'. The search value type can be found in the [searchParam](resources/CapabilitySatement_searchParam.csv) table.|
|present|The matched serial id in the [interaction](resources/CapabilityStatement_interaction.csv) table.|
|present_code|The matched [interaction](resources/CapabilityStatement_interaction.csv) Code (SHALL/SHOULD/MAY) in the interaction table.|
|request_id|The original request ID from the request table in the database.|
|request_uri|The original request uri from the test requests.|
|response_status|The response status from server in the response table from database.|
