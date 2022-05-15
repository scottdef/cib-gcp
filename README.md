# Consul Image Builder for Google Cloud Platform (GCP)

This base system is designed for GCP, but could be ported to any platform with Nomad.

The underlying architecture utilizes the Hashicorp stack in an unorthodox manner. 

How it operates:
- It builds configured, production-ready consul images with packer, then deploys them into a consul cluster on GCP with cloud build.
- The consul cluster is configured with base templates for everything(servers,clients,mTLS,routing,services,etc.)
- These templates effectively allow an autonomous service mesh capable of deploying services from packer images
    similar to how the consul cluster itself is deployed.
- Each app deployed is provided with required gateway and proxies to be fully accessible by whatever it needs.
    
What is required to achieve the above results:
- pre-existing image running app source code intended for deployment.
- service deployment form 
- secrets secured in vault or other secret manager required for operation
- what other deployed services (in-mesh and external) are needed.
- user entity group which needs access (ssh jumpbox running teleport enabling service/resource access is provided)


Each Module has the following folder structure:

- [modules](https://github.com/scottdef/cib-gcp/tree/master/modules): This folder contains the builder
  code, broken down into one or more submodules.
- [bootstrap](https://github.com/scottdef/cib-gcp/tree/master/bootstrap): This folder contains examples
  of how to use the submodules.
- [configs](https://github.com/scottdef/cib-gcp/tree/master/configs): Automated tests for the submodules and
  examples.
