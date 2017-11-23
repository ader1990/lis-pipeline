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
        post {
            always {
                junit 'scripts/lis_hyperv_platform/Report-KVP.xml'
            }
        }
    }

  }
  environment {
    KERNEL_ARTIFACTS_PATH = 'kernel-artifacts'
    DESIRED_KERNEL_NAME = '4.14.0-rc6-00040-g35c48f1-dirty'
  }
}
