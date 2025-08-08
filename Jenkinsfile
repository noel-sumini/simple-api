pipeline {
  agent any
  triggers { githubPush() }

  stages {
    stage('Checkout') {
      steps {
        // Job Config > Environment Variables 에서 설정한 GIT_REPO 사용
        git url: env.GIT_REPO, branch: 'main'
      }
    }

    stage('Prepare Remote') {
      steps {
        timeout(time: 1, unit: 'MINUTES') {
          // Job Config > Global credentials 에 등록한 SSH 키 ID
          sshagent([env.SSH_CRED_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} \\
                'rm -rf ${env.APP_DIR} && mkdir -p ${env.APP_DIR}'
            """
          }
        }
      }
    }

    stage('Copy Sources') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          sshagent([env.SSH_CRED_ID]) {
            sh """
              scp -o StrictHostKeyChecking=no -r * \\
                ${env.DEPLOY_USER}@${env.DEPLOY_HOST}:${env.APP_DIR}
            """
          }
        }
      }
    }
    stage('Build & Deploy') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sshagent([env.SSH_CRED_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} "\
                cd ${env.APP_DIR} && \
                docker build -t ${env.IMAGE_NAME} . && \
                (docker rm -f ${env.CONTAINER_NAME} || true) && \
                docker run -d --name ${env.CONTAINER_NAME} -p 3000:3000 ${env.IMAGE_NAME} \
              "
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo '✅ 배포 완료!'
    }
    failure {
      echo '❌ 배포 실패. 로그를 확인하세요.'
    }
  }
}
