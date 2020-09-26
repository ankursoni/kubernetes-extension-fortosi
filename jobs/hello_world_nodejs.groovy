multibranchPipelineJob("hello-world-nodejs") {
    branchSources {
        git {
            id = "hello-world-nodejs"
            remote("https://github.com/ankursoni/kubernetes-extension-fortio.git")
            credentialsId("github-credentials")
            configure {
                def traitBlock = it / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' / 'traits' 
                traitBlock << 'jenkins.plugins.git.traits.CloneOptionTrait' {
                    extension(class: 'hudson.plugins.git.extensions.impl.CloneOption') {
                        shallow(false)
                        noTag(true)
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