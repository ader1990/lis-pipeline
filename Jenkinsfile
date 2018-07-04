pipeline {
    agent none

    stages {
        stage("build and deploy on Windows and Linux") {
            parallel {
                stage("windows") {
                    agent {
                        label "meta_slave"
                    }
                    stages {
                        stage("build") {agent {
                        label "meta_slave"
                    }
                            steps {
                                echo "run-build.bat"
                            }
                        }
                        stage("deploy") {agent {
                        label "meta_slave"
                    }
                            steps {
                                echo "run-deploy.bat"
                            }
                        }
                    }
                }

                stage("linux") {
                    agent {
                        label "meta_slave"
                    }
                    stages {
                        stage("build") {
                            steps {
                                echo "./run-build.sh"
                            }
                        }
                        stage("deploy") {
                             steps {
                                echo "./run-deploy.sh"
                            }
                        }
                    }
                }
            }
        }
    }
}
