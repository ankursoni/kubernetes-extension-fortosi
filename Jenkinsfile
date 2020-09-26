pipeline {
    agent any

    stages {
        stage("Create Pipeline Jobs") {
            steps {
                jobDsl targets: "jobs/*.groovy"
            }
        }
    }
}