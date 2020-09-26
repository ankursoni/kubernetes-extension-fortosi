multibranchPipelineJob("hello-world-nodejs") {
    branchSources {
        git {
            id = "hello-world-nodejs"
            remote("https://github.com/ankursoni/kubernetes-extension-fortio.git")
            credentialsId("github-credentials")
            withTraits {
                gitBranchDiscovery()
                gitTagDiscovery()
                cloneOptionTrait {
                    extension {
                        shallow(false)
                        noTags(false)
                        reference("")
                        honorRefspec(false)
                    }
                }
            }
        }
    }
    configure {
        it / 'factory' << 'scriptPath'('demo-apps/hello-world-nodejs/pipeline/Jenkinsfile')
    }
    triggers {
        periodic(5)
    }
}