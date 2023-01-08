pipeline {
    parameters {
        string(name: "appVersion", defaultValue: "1.0")
        string(name: "ecrHost", defaultValue: "")
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')
    }

    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')

        TF_VAR_keyName = 'devops-cert_task-key'

        sshCredsID = 'AWS_UBUNTU_INSTANCE_SSH_KEY'
        repositoryName = 'cert_task'
        registryCredsID = 'AWS_ECR_CREDENTIALS'
    }

    stages {

        ///////////////////////////////
        /// Terrafotm stages
        ///////////////////////////////

        stage('Plan') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            steps {
                sh 'terraform init -input=false'
                sh "terraform plan -input=false -out tfplan"
                sh 'terraform show -no-color tfplan > tfplan.txt'
            }
        } // stage Plan

        stage('Approval') {
            when {
                not {
                    equals( expected: true, actual: params.autoApprove )
                }
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            steps {
                script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        } // stage Approval

        stage('Apply') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }
            
            steps {
                sh "terraform apply -input=false tfplan"
                script {
                    builderDnsName = sh(
                       script: "terraform output -raw builder_dns_name",
                       returnStdout: true
                    ).trim()
                    webserverDnsName = sh(
                       script: "terraform output -raw webserver_dns_name",
                       returnStdout: true
                    ).trim()
                }
            }
        } // stage Apply

        ///////////////////////////////
        /// Ansible stages
        ///////////////////////////////

        stage('Ansible playbook') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            steps {
                sh "if [ -f hosts ]; then rm hosts; fi"
                sh "echo '[builder]' >> hosts"
                sh "[ '${builderDnsName}' = '' ] || echo ${builderDnsName} >> hosts"
                sh "echo '[webserver]' >> hosts"
                sh "[ '${webserverDnsName}' = '' ] || echo ${webserverDnsName} >> hosts"
                ansiblePlaybook(
                    playbook: 'prepare-instances.yml',
                    inventory: 'hosts',
                    credentialsId: "${sshCredsID}",
                    disableHostKeyChecking: true,
                    become: true,
                )
            }
        } // stage Ansible playbook

        ///////////////////////////////
        /// Builder stages
        ///////////////////////////////

        stage('Builder fetch and build') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            environment {
                DOCKER_HOST="ssh://ubuntu@${builderDnsName}"
            }

            steps {
                sshagent( credentials:["${sshCredsID}"] ) {
                    sh "docker build --build-arg APPVERSION=${params.appVersion} --tag ${params.ecrHost}/${repositoryName}:${params.appVersion} ."
                }
            }
        } // stage Builder fetch and build

        stage('Builder push to the registry') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            environment {
                DOCKER_HOST="ssh://ubuntu@${builderDnsName}"
            }

            steps {
                sshagent( credentials:["${sshCredsID}"] ) {
                    withDockerRegistry( [credentialsId:"${registryCredsID}", url:"https://${params.ecrHost}"] ) {
                        sh "docker push ${params.ecrHost}/${repositoryName}:${params.appVersion}"
                    }
                }
            }
        } // stage Builder push to the registry

        ///////////////////////////////
        /// Webserver stages
        ///////////////////////////////

        stage('Webserver stop and remove') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            environment {
                DOCKER_HOST="ssh://ubuntu@${webserverDnsName}"
            }

            steps {
                sshagent( credentials:["${sshCredsID}"] ) {
                    sh "for ID in \$(docker ps -q); do docker stop \$ID; done"
                    sh "for ID in \$(docker ps -a -q); do docker rm \$ID; done"
                    sh "for ID in \$(docker images -q); do docker rmi \$ID; done"
                }
            }
        } // stage Webserver stop and remove

        stage('Webserver pull and start') {
            when {
                not {
                    equals( expected: true, actual: params.destroy )
                }
            }

            environment {
                DOCKER_HOST="ssh://ubuntu@${webserverDnsName}"
            }

            steps {
                sshagent( credentials:["${sshCredsID}"] ) {
                    withDockerRegistry( [credentialsId:"${registryCredsID}", url:"https://${params.ecrHost}"] ) {
                        sh "docker pull ${params.ecrHost}/${repositoryName}:${params.appVersion}"
                    }
                    sh "docker run -p 80:5000 -d ${params.ecrHost}/${repositoryName}:${params.appVersion}"
                    echo "########################################################################################"
                    echo "### curl http://${webserverDnsName}"
                    echo "########################################################################################"
                }
            }
        } // stage Webserver pull and start

        ///////////////////////////////////
        /// Terraform Destroy and cleanws
        ///////////////////////////////////

        stage('Destroy') {
            when {
                equals( expected: true, actual: params.destroy )
            }
        
            steps {
                sh 'terraform destroy --auto-approve'
                cleanWs()
            }
        } // stage Destroy

    } // stages
}
