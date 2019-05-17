pipeline {
  agent {
      label 'linux && amd64 && ubuntu-1804 && docker'
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
        sh 'make clean'
        sh 'make build'
      }
    }
    stage('test') {
      steps {
        sh 'make test'
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
