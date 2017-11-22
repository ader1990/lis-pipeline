def PowerShell(psCmd) {
    bat "powershell.exe -NonInteractive -ExecutionPolicy Bypass -Command \"\$ErrorActionPreference='Stop';[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;$psCmd;EXIT \$global:LastExitCode\""
}

pipeline {
  agent {
    node {
      label 'hyper-v'
    }
    
  }
  stages {
    stage('Run LIS') {
        steps {
            powershell 'write-output "sdfsadfasfda"'
        }
    }
  }
  environment {
    KERNEL_GIT_BRANCH = 'unstable'
    KERNEL_ARTIFACTS_PATH = 'kernel-artifacts'
    THREAD_NUMBER = 'x1'
    UBUNTU_VERSION = '16'
    BUILD_PATH = '/mnt/tmp/kernel-build-folder'
    KERNEL_CONFIG = './Microsoft/config-azure'
    CLEAN_ENV = 'False'
    USE_CCACHE = 'True'
    MAX_RETRIES = '40'
    DESIRED_KERNEL_NAME = '4.14.0-rc6-00040-g35c48f1-dirty'
    BUILD_NAME = 'qua'
  }
}
