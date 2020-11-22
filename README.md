# client-fhir-testing
Tool to test a client's conformance with a FHIR implementation guide.


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

The following will read options from `proxy.yml`.  If the `proxy.yml` file does 
not exist, 
one with default options will be created for you.  It is important to set `backend` 
config option as this is the destination the proxy forwards to.
```sh
ruby start-proxy.rb
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
