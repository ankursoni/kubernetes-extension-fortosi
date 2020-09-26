multibranchPipelineJob("hello-world-aspnetcore") {
    branchSources {
        git {
            id = "hello-world-aspnetcore"
            remote("https://github.com/${ORG_NAME}/kubernetes-extension-fortio.git")
            credentialsId("github-credentials")
            traits {
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
        it / 'factory' << 'scriptPath'('demo-apps/hello-world-aspnetcore/pipeline/Jenkinsfile')
    }
    triggers {
        periodic(5)
    }
}