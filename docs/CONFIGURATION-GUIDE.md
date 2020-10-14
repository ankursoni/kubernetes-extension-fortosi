# fortosi configuration guide

## Directory structure

This project has the following directory structure:
* **demo-apps** -  
this directory has 2 hello-world applications written in aspnetcore and nodejs including an individual 'pipeline' subdirectory that contains 'pipeline as code' definition (Jenkinsfile) and [helm](https://helm.sh/) chart for deployment packaging. Additionally, a 'scripts' directory outside of the applications contains common scripts to deploy to [docker](https://www.docker.com/) or [kubernetes](https://kubernetes.io/) environment.
* **docs, docs/images and docs/gifs** -  
this directory is a placeholder for documentation, images and animations respectively.
* **infra/aws and infra/azure** -  
this directory is a placeholder for 'infrastructure as code' in the form of [terraform](https://www.terraform.io/) script and associated artifects like terraform state and provider files for both aws and azure.
* **jenkins/agent** - this contains Dockerfile and helm chart needed to generate package deployment yaml for jenkins-agent.
* **jenkins/master** - this contains Dockerfile and helm chart needed to generate package deployment yaml for jenkins-master.
* **jenkins/scripts** - this contains scripts to execute [jenkins](https://www.jenkins.io/) installation on local docker environment.
* **jobs** - this contains 'job as definition' for the 2 demo application pipelines.
* **scripts** -  
this contains bash shell scripts that are needed for this extension to work. 'auto-setup.sh' is a special file that is the kubectl extension execution script.
* **vars** -  
this directory is designated for storing the shared library of pipeline definitions as described here: https://www.jenkins.io/doc/book/pipeline/shared-libraries/

## Configurability options

After a demo run as described [here](../README.md#automatic-installation-of-jenkins-on-kubernetes), one can use this extension to the fullest by configuring the following options:
* **GITHUB_ORG** -  
this variable designates your github organisation name and can be home to multiple repositories forming the suite of applications or micro services that you intend to ship to kubernetes.
* **INIT_REPO** - 
this variable designates the initial repository in your github organisation that contains Jenkinsfile similar to the one [here](../Jenkinsfile). This Jenkinsfile is responsible to initiate creation of **jobs as code** that are needed to setup pipeline instances for the suite of applications in various other repositories.
* **vars/cicd.groovy** -  
this is a **pipeline as code** shared library groovy file that proves that no matter what the underlying technology platform, the apps can be continuously integrated and continuously delivered using the exact same pipeline definition by leveraging the power of docker. This groovy library file is invoked by the 2 demo applications from their respective 'demo-apps/hello-world-.../pipeline/Jenkinsfile' and demonstrates the abstraction provided by docker in each of the build, test, publish and deploy stages.
* **jenkins/master/plugins.txt** -  
this file contains the **plugins as code** i.e. initial set of jenkins plugins to be installed on first run. You can add or remove from the list as per your needs. But this list is effective only for the first time run. Or, you can delete the jenkins home directory to simulate first time run again (not recommended).
* **jenkins/master/jenkins.yaml** -  
this file contains the **configuration as code** for various plugins and initial set of jenkins credentials that are seeded with the first time run. You can add more to it by visiting [here](https://github.com/jenkinsci/configuration-as-code-plugin).
* **jenkins/agent/Dockerfile** -  
this is the 'jenkins-agent' docker file that can be modified to add or remove the agent capabilities.
* **jenkins > credentials > global credentials > 'kubeconfig-secret'** -  
this contains the kube-config file needed in the 'deploy' stage to connect to the target kubernetes cluster. You can update this file to potentially start deploying to some other kubernetes cluster. You may also create more such credentials and modify the shared pipeline definition to start deploying to more than one cluster, if desired.