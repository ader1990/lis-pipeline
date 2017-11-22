pipeline {
  agent {
    node {
      label 'ubuntu_kernel_builder'
    }
    
  }
  stages {
    stage('Build Kernel') {
      steps {
        withCredentials([string(credentialsId: 'KERNEL_GIT_URL', variable: 'KERNEL_GIT_URL')]) {
          sh '''#!/bin/bash
            set -xe

            echo "Building artifacts..."

            pushd "$WORKSPACE/scripts/package_building"
            JOB_KERNEL_ARTIFACTS_PATH="${BUILD_NUMBER}-${KERNEL_ARTIFACTS_PATH}"
            bash build_artifacts.sh \\
                --git_url ${KERNEL_GIT_URL} \\
                --git_branch ${KERNEL_GIT_BRANCH} \\
                --destination_path ${JOB_KERNEL_ARTIFACTS_PATH} \\
                --install_deps True \\
                --thread_number ${THREAD_NUMBER} \\
                --debian_os_version ${UBUNTU_VERSION} \\
                --build_path ${BUILD_PATH} \\
                --kernel_config ${KERNEL_CONFIG} \\
                --clean_env ${CLEAN_ENV} \\
                --use_ccache ${USE_CCACHE}

            popd
            '''
        }
      }
    }
    stage('Test Kernel') {
      steps {
        withCredentials([string(credentialsId: 'KERNEL_GIT_URL', variable: 'KERNEL_GIT_URL'),
                         string(credentialsId: 'SMB_SHARE_URL', variable: 'SMB_SHARE_URL'),
                         usernamePassword(credentialsId: 'smb_share_user_pass', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')
                         ]) {
          sh '''#!/bin/bash
            pushd ./scripts/azure_kernel_validation
            bash create_azure_vm.sh --build_number $BUILD_NAME --clone_repo y --vm_params \
              "username=$USERNAME,password=$PASSWORD,samba_path=$SMB_SHARE_URL/unstable-kernels" \
              --deploy_data azure_kernel_validation --resource_group kernel-validation
            popd

            . ./scripts/package_building/utils.sh
            INTERVAL=5
            COUNTER=0
            while [ $COUNTER -lt $MAX_RETRIES ]; do
                public_ip_raw=$(az network public-ip show --name "$BUILD_NAME-PublicIP" --resource-group kernel-validation --query '{address: ipAddress }')
                public_ip=`echo $public_ip_raw | awk '{if (NR == 1) {print $3}}' | tr -d '"'`
                if [ !  -z $public_ip ]; then
                    echo "Public ip available: $public_ip."
                    break
                else
                    echo "Public ip not available."
                fi
                let COUNTER=COUNTER+1

                if [ -n "$INTERVAL" ]; then
                    sleep $INTERVAL
                fi
            done
            if [ $COUNTER -eq $MAX_RETRIES ]; then
                echo "Failed to get public ip. Exiting..."
                exit 2
            fi

            INTERVAL=5
            COUNTER=0
            while [ $COUNTER -lt $MAX_RETRIES ]; do
                KERNEL_NAME=`ssh -i ~/azure_priv_key.pem -o StrictHostKeyChecking=no ubuntu@$public_ip uname -r`
                echo $KERNEL_NAME
                if [ $KERNEL_NAME == $DESIRED_KERNEL_NAME ]; then
                    echo "Kernel matched."
                    exit 0
                else
                    echo "Kernel $KERNEL_NAME does not match with desired Kernel: $DESIRED_KERNEL_NAME"
                fi
                let COUNTER=COUNTER+1

                if [ -n "$INTERVAL" ]; then
                    sleep $INTERVAL
                fi
            done

            exit 1
            '''
        }
      }
      post {
        always {
          sh '''#!/bin/bash
            pushd ./scripts/azure_kernel_validation
            bash remove_azure_vm_resources.sh $BUILD_NAME
            popd
            '''
        }
        failure {
          sh 'echo "Load failure test results."'
          nunit(testResultsPattern: 'scripts/azure_kernel_validation/tests-fail.xml')
        }
        success {
          nunit(testResultsPattern: 'scripts/azure_kernel_validation/tests.xml')
          withCredentials([string(credentialsId: 'KERNEL_GIT_URL', variable: 'KERNEL_GIT_URL'),
                           string(credentialsId: 'SMB_SHARE_URL', variable: 'SMB_SHARE_URL'),
                           usernamePassword(credentialsId: 'smb_share_user_pass', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')
                           ]) {
            sh '''#!/bin/bash
                set -xe

                MOUNT_POINT="/tmp/${BUILD_NUMBER}"
                mkdir -p $MOUNT_POINT

                sudo mount -t cifs "${SMB_SHARE_URL}/${KERNEL_GIT_BRANCH}-kernels" $MOUNT_POINT \
                      -o vers=3.0,username=${USERNAME},password=${PASSWORD},dir_mode=0777,file_mode=0777,sec=ntlmssp

                JOB_KERNEL_ARTIFACTS_PATH="${BUILD_NUMBER}-${KERNEL_ARTIFACTS_PATH}"
                relpath_kernel_artifacts=$(realpath "scripts/package_building/${JOB_KERNEL_ARTIFACTS_PATH}")
                sudo cp -rf "${relpath_kernel_artifacts}/msft"* $MOUNT_POINT

                sudo umount $MOUNT_POINT
            '''
            archiveArtifacts ("scripts/package_building/" + env.BUILD_NUMBER + "-" + env.KERNEL_ARTIFACTS_PATH + "/latest/**/*.deb")
          }
        }
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