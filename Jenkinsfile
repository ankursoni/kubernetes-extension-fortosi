pipeline {
  agent any
  
  environment {
      ORG_NAME="ankursoni"
  }

  stages {
    stage("Create Pipeline Jobs") {
      steps {
        jobDsl scriptText: """
            multibranchPipelineJob("hello-world-aspnetcore") {
                branchSources {
                    git {
                        id = "hello-world-aspnetcore"
                        remote("https://github.com/${ORG_NAME}/kubernetes-extension-fortio.git")
                        credentialsId("github-credentials")
                    }
                }
                configure {
                    it / 'factory' << 'scriptPath'('demo-apps/hello-world-aspnetcore/pipeline/Jenkinsfile')
                }
                triggers {
                    periodic(5)
                }
            }
        """
        jobDsl scriptText: """
            multibranchPipelineJob("hello-world-nodejs") {
                branchSources {
                    git {
                        id = "hello-world-nodejs"
                        remote("https://github.com/${ORG_NAME}/kubernetes-extension-fortio.git")
                        credentialsId("github-credentials")
                    }
                }
                configure {
                    it / 'factory' << 'scriptPath'('demo-apps/hello-world-nodejs/pipeline/Jenkinsfile')
                }
                triggers {
                    periodic(5)
                }
            }
        """
      }
    }
  }
}