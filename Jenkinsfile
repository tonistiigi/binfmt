pipeline {
  agent {
      label 'linux && amd64 && docker'
  }
  parameters {
    booleanParam(name: "push", defaultValue: false)
  }
  options {
    timeout(time: 1, unit: 'HOURS')
    timestamps()
    ansiColor('xterm')
  }
  stages {
    stage('build') {
      steps {
        sh 'make build'
      }
    }
    stage('push') {
      when {
        beforeAgent true
        expression { params.push }
      }
      steps {
        withDockerRegistry(url: "https://index.docker.io/v1/", credentialsId: 'dockerbuildbot-index.docker.io') {
          sh 'make push'
        }
      }
    }
  }
}
