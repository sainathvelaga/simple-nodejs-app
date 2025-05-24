pipeline {
    agent {
        label 'AGENT-1'
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }
    environment{
        def appVersion = '' //variable declaration
        nexusUrl = 'nexus.sainathdevops.space:8081'
        region = "us-east-1"
        account_id = "654654239129"
    }
    stages {
        stage('read the version'){
            steps{
                script{
                    def packageJson = readJSON file: 'package.json'
                    appVersion = packageJson.version
                    echo "application version: $appVersion"
                }
            }
        }
        
        stage('Build'){
            steps{
                sh """
                zip -q -r nodejs-app-${appVersion}.zip * -x Jenkinsfile -x Dockerfile -x nodejs-app-${appVersion}.zip
                ls -ltr
                """
            }
        }

        stage ('Archive artifacts'){
            steps{
                archiveArtifacts artifacts: "nodejs-app-${appVersion}.zip", fingerprint: true
                sh 'ls -la'
            }
        }



        // stage('Deploy'){
        //     steps{
        //         sh """
        //             aws eks update-kubeconfig --region us-east-1 --name expense-dev
        //             cd helm
        //             sed -i 's/IMAGE_VERSION/${appVersion}/g' values.yaml
        //             helm upgrade frontend .
        //         """
        //     }
        // }
        stage('Snyk Test') {
           steps {
               script {
                   // Run Snyk test
                   withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                       sh 'snyk test --token=$SNYK_TOKEN --severity-threshold=high --all-projects  || true'
                       // If you want to fail the build on vulnerabilities, uncomment the next line

                   }
               }
           }
       }

       stage('SonarQube Analysis') {
           steps {
               script {
                   // Run SonarQube analysis
                   withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                       sh """
                           wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
                           unzip sonar-scanner-cli-5.0.1.3006-linux.zip
                           export PATH=$PWD/sonar-scanner-*/bin:$PATH
                           sonar-scanner \
                           -Dsonar.projectKey=nodejs-app \
                           -Dsonar.sources=. \
                           -Dsonar.host.url=http://nexus.sainathdevops.space:9000 \
                           -Dsonar.login=$SONAR_TOKEN
                       """
                   }
               }
           }
       }

        stage('Nexus Artifact Upload'){
            steps{
                script{
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: "${nexusUrl}",
                        groupId: 'com.nodejs',
                        version: "${appVersion}",
                        repository: 'simple-nodejs-repo',
                        credentialsId: 'nexus-auth',
                        artifacts: [
                            [
                                artifactId: 'nodejs-app',
                                classifier: '',
                                file: "nodejs-app-" + "${appVersion}" + '.zip',
                                type: 'zip'
                            ]
                        ]
            )
                }
            }


        }

        stage('Docker build'){
            steps{
                sh """
                    aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com

                    docker build -t ${account_id}.dkr.ecr.${region}.amazonaws.com/nodejs-app:${appVersion} .

                    docker push ${account_id}.dkr.ecr.${region}.amazonaws.com/nodejs-app:${appVersion}
                """
            }
        }


        // stage('Deploy'){
        //     steps{
        //         script{
        //             def params = [
        //                 string(name: 'appVersion', value: "${appVersion}")
        //             ]
        //             build job: 'frontend-deploy', parameters: params, wait: false
        //         }
        //     }
        // } */
    }
    post { 
        always { 
            echo 'I will always say Hello again!'
            // deleteDir()
        }
        success { 
            echo 'I will run when pipeline is success'
        }
        failure { 
            echo 'I will run when pipeline is failure'
        }
    }
}