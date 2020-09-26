multibranchPipelineJob("hello-world-aspnetcore") {
    branchSources {
        git {
            id = "hello-world-aspnetcore"
            remote("https://github.com/ankursoni/kubernetes-extension-fortio.git")
            credentialsId("github-credentials")
            configure {
                def traitBlock = it / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' / 'traits' 
                traitBlock << 'jenkins.plugins.git.traits.CloneOptionTrait' {
                    extension(class: 'hudson.plugins.git.extensions.impl.CloneOption') {
                        shallow(false)
                        noTag(false)
                        reference("")
                        honorRefspec(true)
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