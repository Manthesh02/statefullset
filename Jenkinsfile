pipeline {
    agent any

    parameters {
        string(defaultValue: '1.0.0', description: 'Version number for the build', name: 'VERSION')
    }

    environment {
        GIT_USER_EMAIL = 'vmanthesh20@gmail.com'
        GIT_USER = 'Manthesh02'
        DOCKERHUB_CREDENTIALS = 'dockerhub'
        NAMESPACE = 'test'
    }

    tools {
        maven 'Maven'
    }

    stages {
        stage('Git Configuration') {
            steps {
                sh "git config --global user.email '${env.GIT_USER_EMAIL}'"
                sh "git config --global user.name '${env.GIT_USER}'"
            }
        }

        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Github', url: 'git@github.com:Manthesh02/Publish.git']])
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Tag and Push') {
            steps {
                sh "git tag -a ${params.VERSION} -m 'Version ${params.VERSION}'"
                sh 'git push origin --tags'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t manthesh/java-app:${params.VERSION} ."
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    withCredentials([string(credentialsId: env.DOCKERHUB_CREDENTIALS, variable: 'DOCKERHUB_PASSWORD')]) {
                        sh "docker login -u manthesh -p '${DOCKERHUB_PASSWORD}'"
                        sh "docker push manthesh/java-app:${params.VERSION}"
                    }
                }
            }
        }

        stage('Tag and Deploy New Images for Deployments') {
            steps {
                script {
                    def newVersion = params.VERSION

                    // Retrieve current images for Deployments
                    def deploymentNames = sh(script: "kubectl get deployments -n ${env.NAMESPACE} -o jsonpath='{.items[*].metadata.name}'", returnStdout: true).trim().split('\n')
                    deploymentNames.each { deploymentName ->
                        // Retrieve current image
                        def currentImage = sh(script: "kubectl get deployment ${deploymentName} -n ${env.NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}'", returnStdout: true).trim()
                        
                        if (currentImage) {
                            echo "Deployment: ${deploymentName}, Current Image: ${currentImage}"
                            
                            // Tag and republish image with new version
                            def newImage = "${currentImage.split(':')[0]}:${newVersion}"
                            sh "docker tag ${currentImage} ${newImage}"
                            sh "docker push ${newImage}"
                            
                            // Update Deployment to use new image
                            sh "kubectl set image deployment/${deploymentName} ${deploymentName}=${newImage} -n ${env.NAMESPACE}"
                            echo "Deployment ${deploymentName} updated to use new image: ${newImage}"
                        } else {
                            echo "Failed to retrieve current image for Deployment ${deploymentName}. Skipping..."
                        }
                    }
                }
            }
        }

        stage('Deploy to k3s') {
            steps {
                script {
                    def deploymentYAML = readFile '/var/lib/jenkins/workspace/publish/app.yaml'
                    deploymentYAML = deploymentYAML.replaceAll('\\$\\{VERSION\\}', params.VERSION)
                    sh "echo '''${deploymentYAML}''' | /usr/local/bin/kubectl apply -f - --kubeconfig /etc/rancher/k3s/k3s.yaml"
                }
            }
        }
    }
}
