def call(String appName) {
    pipeline {
        agent { label 'jenkins-agent' }

        environment {
            APP_NAME="${appName}"
            APP_PATH="demo-apps/${APP_NAME}"
            CICD_PATH="${APP_PATH}/pipeline"
            SCRIPT_PATH="demo-apps/scripts"
            MAIN_BRANCH="master"
            GIT_DESCRIBE=sh(returnStdout: true, script: "echo -n \$(git describe --always)")
            IMAGE_VERSION=sh(returnStdout: true, script: "[ $GIT_BRANCH = $MAIN_BRANCH ] && echo -n ${GIT_DESCRIBE} || echo -n ${GIT_BRANCH}-${GIT_DESCRIBE} | sed -e 's/\\//-/g'")
            IMAGE_NAME="${CONTAINER_REGISTRY_URL}/${CONTAINER_REPOSITORY_NAME}/${APP_NAME}"
            IMAGE_TAG="${IMAGE_NAME}:${IMAGE_VERSION}"
            KUBERNETES_NAMESPACE="default"
        }

        stages {
            stage ("Build") {
                steps {
                    sh "env"
                    sh "docker build --network=host \
                            -f ${APP_PATH}/Dockerfile \
                            -t ${IMAGE_TAG} ${APP_PATH}/."
                }
            }
            stage ("Test") {
                steps {
                    sh "docker build --network=host \
                            -f ${APP_PATH}/tests/Dockerfile \
                            --build-arg BUILD_IMAGE=${IMAGE_TAG} \
                            -t ${IMAGE_TAG}-test ${APP_PATH}/."
                }
            }
            stage ("Publish") {
                steps {
                    withCredentials(
                        bindings: [
                            usernamePassword(credentialsId: "container-registry-credentials", usernameVariable: "CONTAINER_REGISTRY_USER_NAME", passwordVariable: "CONTAINER_REGISTRY_USER_PASSWORD")
                        ]
                    ) {
                        sh "docker login -u ${CONTAINER_REGISTRY_USER_NAME} -p ${CONTAINER_REGISTRY_USER_PASSWORD} ${CONTAINER_REGISTRY_URL}"
                    }
                    sh "docker push ${IMAGE_TAG}"
                }
            }
            stage ("Deploy") {
                steps {
                    sh "cd ${SCRIPT_PATH}; chmod +x *.sh"
                    script {
                        if (env.ENABLE_LOCAL_DOCKER == 'true') {
                            sh "cd ${SCRIPT_PATH}; ./docker.sh ${APP_NAME} ${IMAGE_TAG}"
                        }
                        else {
                            withCredentials(
                                bindings: [
                                    file(credentialsId: "kubeconfig-secret", variable: "kubeconfig")
                                ]
                            ) {
                                sh "mkdir -p ~/.kube"
                                sh "cp \$kubeconfig ~/.kube/config"
                                sh "cd ${SCRIPT_PATH}; ./kubernetes.sh ${KUBERNETES_NAMESPACE} ${CONTAINER_REGISTRY_URL} ${CONTAINER_REPOSITORY_NAME} ${IMAGE_TAG} ${APP_NAME}"
                            }
                        }
                    }
                }
            }
        }

        post {
            always {
                sh """
                    docker logout || exit 0
                    docker system prune -f || exit 0
                    docker volume prune -f || exit 0
                """
                script {
                    if (!env.ENABLE_LOCAL_DOCKER) { sh "docker rmi --force ${IMAGE_TAG}-test ${IMAGE_TAG} || exit 0" }
                }
            }
        }
    }
}