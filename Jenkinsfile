pipeline {
  agent any
  triggers { githubPush() }

  environment {
    SHORT_COMMIT = "${GIT_COMMIT[0..6]}"  
  }

  stages {
    stage('Checkout') {
      steps {
        git url: env.GIT_REPO, branch: 'main'
      }
    }

    stage('Build') {
      steps {
        timeout(time: 20, unit: 'MINUTES') {
          sh '''
            set -euxo pipefail
            : "${DOCKER_IMAGE:?DOCKER_IMAGE not set}"   # 예: ysm2820/simple-api
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
              set -euxo pipefail
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
              docker push "${DOCKER_IMAGE}:${SHORT_COMMIT}"
              docker push "${DOCKER_IMAGE}:latest"
              docker logout || true
            '''
          }
        }
      }
    }

    stage('Pull (remote)') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sshagent([env.SSH_CRED_ID]) {
            withCredentials([usernamePassword(
              credentialsId: 'dockerhub-creds',
              usernameVariable: 'DOCKER_USER',
              passwordVariable: 'DOCKER_PASS'
            )]) {
              sh """
                ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} "\
                  (echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin || true) && \
                  docker pull ${env.DOCKER_IMAGE}:${SHORT_COMMIT} \
                "
              """
            }
          }
        }
      }
    }

    stage('Deploy (remote)') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sshagent([env.SSH_CRED_ID]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER}@${env.DEPLOY_HOST} "\
                (docker rm -f ${env.CONTAINER_NAME} || true) && \
                docker run -d --name ${env.CONTAINER_NAME} -p 3000:3000 \
                  ${env.DOCKER_IMAGE}:${SHORT_COMMIT} \
              "
            """
          }
        }
      }
    }
  }

  post {
    success { echo 'Deploy 성공' }
    failure { echo 'Deploy Fail' }
  }
}
