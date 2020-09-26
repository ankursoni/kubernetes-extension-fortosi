multibranchPipelineJob("hello-world-aspnetcore") {
    branchSources {
        git {
            id = "hello-world-aspnetcore"
            remote("https://github.com/ankursoni/kubernetes-extension-fortio.git")
            credentialsId("github-credentials")
        }
    }
    configure {
        it / 'factory' << 'scriptPath'('demo-apps/hello-world-aspnetcore/pipeline/Jenkinsfile')
        it / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' << 'traits' {
            'jenkins.plugins.git.traits.BranchDiscoveryTrait' { }
            'jenkins.plugins.git.traits.CloneOptionTrait' {
                'extension'(class: 'hudson.plugins.git.extensions.impl.CloneOption') {
                    shallow(false)
                    noTags(false)
                    reference()
                    honorRefspec(false)
                }
            }
        }
    }
    triggers {
        periodic(5)
    }
}