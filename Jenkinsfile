pipeline {
  agent any
  triggers { githubPush() }

  environment {
    COMPOSE_FILES  = 'docker-compose.yml'
  }

 stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.SHORT_COMMIT = sh(script: "git rev-parse --short=7 HEAD || echo unknown", returnStdout: true).trim()
          echo "SHORT_COMMIT=${env.SHORT_COMMIT}"
        }
      }
    }

    stage('Build') {
      steps {
        timeout(time: 20, unit: 'MINUTES') {
          sh '''
            : "${DOCKER_IMAGE:?DOCKER_IMAGE not set}"
            docker build -t "${DOCKER_IMAGE}:${SHORT_COMMIT}" -t "${DOCKER_IMAGE}:latest" .
          '''
        }
      }
    }

    stage('Push') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh '''
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
              docker push "${DOCKER_IMAGE}:${SHORT_COMMIT}"
              docker push "${DOCKER_IMAGE}:latest"
              docker logout || true
            '''
          }
        }
      }
    }

    stage('Sync compose files to remote') {
      steps {
        sshagent([env.SSH_CRED_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} 'mkdir -p ${env.REMOTE_DIR}'
            scp -o StrictHostKeyChecking=no docker-compose*.yml ${env.DEPLOY_USER}@${env.DEPLOY_HOST}:${env.REMOTE_DIR}/
            # scp -o StrictHostKeyChecking=no .env ${env.DEPLOY_USER}@${env.DEPLOY_HOST}:${env.REMOTE_DIR}/
          """
        }
      }
    }

    stage('Deploy with docker-compose (remote)') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          sshagent([env.SSH_CRED_ID]) {
            withCredentials([usernamePassword(
              credentialsId: 'dockerhub-creds',
              usernameVariable: 'DOCKER_USER',
              passwordVariable: 'DOCKER_PASS'
            )]) {
              sh """
                ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} '\
                  cd ${env.REMOTE_DIR} && \
                  export DOCKER_IMAGE="${env.DOCKER_IMAGE}" && \
                  export IMAGE_TAG="${env.SHORT_COMMIT}" && \
                  echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin || true && \
                  docker compose -f ${env.COMPOSE_FILES} pull && \
                  docker compose -f ${env.COMPOSE_FILES} up -d && \
                  docker logout || true \
                '
              """
            }
          }
        }
      }
    }
  }

  post {
    success { echo "✅ Deploy 성공: ${DOCKER_IMAGE}:${SHORT_COMMIT}" }
    failure { echo "❌ Deploy Fail" }
    always {
      sh 'docker image prune -f || true'
    }
  }
}
