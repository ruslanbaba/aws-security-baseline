pipeline {
    agent any

    environment {
        TF_WORKSPACE = 'aws-security-baseline-prod'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    sh '''
                        terraform init \
                        -backend-config="organization=${TF_ORGANIZATION}" \
                        -backend-config="workspace=${TF_WORKSPACE}"
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    sh 'tfsec .'
                    sh 'checkov -d .'
                }
            }
        }

        stage('Approval') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                input message: 'Do you want to apply this plan?'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Compliance Check') {
            steps {
                script {
                    // Run AWS Config compliance check
                    sh '''
                        aws configservice start-configuration-recorder \
                        --configuration-recorder-name aws-security-baseline
                    '''
                    
                    // Notify Slack about compliance status
                    def complianceStatus = sh(
                        script: 'aws configservice get-compliance-details-by-config-rule',
                        returnStdout: true
                    ).trim()
                    
                    slackSend(
                        color: '#36a64f',
                        message: "Compliance Check Results:\n${complianceStatus}"
                    )
                }
            }
        }
    }

    post {
        success {
            slackSend(
                color: '#36a64f',
                message: "Security Baseline Deployment Successful\nWorkspace: ${TF_WORKSPACE}"
            )
        }
        failure {
            slackSend(
                color: '#ff0000',
                message: "Security Baseline Deployment Failed\nWorkspace: ${TF_WORKSPACE}"
            )
        }
    }
}
