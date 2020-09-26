pipeline {
    agent any
  
    environment {
        ORG_NAME="ankursoni"
    }

    stages {
        stage("Create Pipeline Jobs") {
            steps {
                jobDsl targets: ["jobs/*.groovy"]
            }
        }
    }
}