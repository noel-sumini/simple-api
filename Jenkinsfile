pipeline {
  agent any

  environment {
    GIT_REPO       = 'https://github.com/noel-sumini/simple-api.git'
    DEPLOY_HOST    = '152.69.230.75'
    DEPLOY_USER    = 'ubuntu'
    SSH_CRED_ID    = 'deploy-server-ssh'
    APP_DIR        = '/home/ubuntu/app'
    IMAGE_NAME     = 'simple-api:latest'
    CONTAINER_NAME = 'simple-api'
  }

  stages {
    stage('Checkout') {
      steps {
        git url: "${GIT_REPO}", branch: 'main'
      }
    }

    stage('Test') {
      steps {
        // 필요 없으면 이 스테이지를 통째로 제거하세요.
        sh 'pytest --maxfail=1 --disable-warnings -q'
      }
    }

    stage('Prepare Remote') {
      steps {
        timeout(time: 1, unit: 'MINUTES') {
          sshagent([SSH_CRED_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} \\
                "rm -rf ${APP_DIR} && mkdir -p ${APP_DIR}"
            """
          }
        }
      }
    }

    stage('Copy Sources') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          sshagent([SSH_CRED_ID]) {
            sh """
              scp -o StrictHostKeyChecking=no -r * \\
                ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}
            """
          }
        }
      }
    }

    stage('Build & Deploy') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sshagent([SSH_CRED_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} << 'EOF'
                cd ${APP_DIR}
                docker build -t ${IMAGE_NAME} .
                # 기존 컨테이너가 있으면 중지 및 삭제
                if docker ps -a --format '{{.Names}}' | grep -q '^${CONTAINER_NAME}\$'; then
                  docker rm -f ${CONTAINER_NAME}
                fi
                # 새 컨테이너 실행
                docker run -d --name ${CONTAINER_NAME} -p 3000:3000 ${IMAGE_NAME}
              EOF
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
