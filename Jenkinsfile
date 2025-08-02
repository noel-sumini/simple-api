pipeline {
  agent any

  environment {
    GIT_REPO       = 'https://github.com/noel-sumini/simple-api.git'
    DEPLOY_HOST    = '152.69.230.75'
    DEPLOY_USER    = 'ubuntu'
    SSH_CRED_ID    = 'deploy-server-ssh'
    APP_DIR        = '/home/deploy/app'
    IMAGE_NAME     = 'simple-api:latest'
    CONTAINER_NAME = 'simple-api'
  }

  stages {
    stage('Checkout') {
      steps {
        git url: "${GIT_REPO}", branch: 'main'
      }
    }

    stage('Prepare Remote') {
      steps {
        sshagent([SSH_CRED_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} \\
              "rm -rf ${APP_DIR} && mkdir -p ${APP_DIR}"
          """
        }
      }
    }

    stage('Copy Sources') {
      steps {
        sshagent([SSH_CRED_ID]) {
          sh """
            scp -o StrictHostKeyChecking=no -r * \\
              ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}
          """
        }
      }
    }

    stage('Build Image') {
      steps {
        sshagent([SSH_CRED_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} << 'EOF'
              cd ${APP_DIR}
              docker build -t ${IMAGE_NAME} .
            EOF
          """
        }
      }
    }

    stage('Deploy Container') {
      steps {
        sshagent([SSH_CRED_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} << 'EOF'
              # 기존 컨테이너가 있으면 중지/삭제
              if docker ps -a --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}\$'; then
                docker rm -f ${CONTAINER_NAME}
              fi
              # 새 컨테이너 실행
              docker run -d \\
                --name ${CONTAINER_NAME} \\
                -p 3000:3000 \\
                ${IMAGE_NAME}
            EOF
          """
        }
      }
    }
  }
}