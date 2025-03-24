pipeline {
    agent any

    /*environment {
        // 定义环境变量
        SERVER_IP = your-server-ip        					// 服务器IP地址
        SERVER_USER = your-username    					// 服务器用户名
        TARGET_DIR = you-jarFileDir                  // 服务器上的目标目录
        JAR_FILE = your-jarFileName                // 打包后的文件名
    }*/

    stages {
        stage('Clone Source Code') {
            steps {
                // 拉取项目源码
                //注意: 这里根据自己的需求选择合适的分支以及仓库地址（ssh或https）
                git branch: 'main', url: 'git@github.com:idlerecord/Imqa-sdk-ios.git'
            }
        }
        stage('Install Tools') {
            steps {
                script{
                    
                    // 确保 Homebrew 路径已添加到环境变量 PATH 中
                     withEnv(["PATH+BREW=/opt/homebrew/bin"]){
                        //install Homebrew
                        def hombrew_installed = sh(script: "brew --version", returnStatus: true)
                        if(hombrew_installed != 0){
                            echo "Installing with Homebrew..."
                            sh '''#!/bin/bash
                            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
                            '''
                        }else{
                            echo "Homebrew is already installed."
                        }

                     
                        def mise_installed = sh(script: "mise --version", returnStatus: true)
                        if(mise_installed != 0){
                            echo "Installing with Mise..."
                            sh 'brew install mise'
                        }else{
                            echo "Mise is already installed."
                        }
                        
                        def cocoapods_installed = sh(script: "pod --version", returnStatus: true)
                        if(cocoapods_installed != 0){
                            echo "Installing with cocoapods..."
                            sh 'brew install cocoapods'
                        }else{
                            echo "cocoapods is already installed."
                        }

                    }

                    //install tuist
                    sh '''
                    if ! Command -v tuist &> /dev/null; then
                        echo "Tuist is not installed. Installing with Tuist..."
                        mise install tuist
                    fi
                    '''
                    
                    /*
                    //install Cocoapods
                    sh '''
                    if ! Command -v pod &> /dev/null; then
                        echo "Cocoapods is not installed. Installing with Cocoapods..."
                        brew install cocoapods
                    fi
                    '''
                    */
                }
            }
        }
        /*stage('Clean Project') {
            // Project clean 작업
            steps {
                //DevrivedData 삭제
                sh 'rm -rf ~/Library/Developer/Xcode/DerivedData/*'
                
                //tuist 삭제
                sh 'tuist clean'
                
                //.xcodeproj .xcworkspace삭제
                sh 'rm -rf *xcodeproj *xcworkspace'
            }
        }*/
        /*stage('Test') {
            steps {
                // 运行测试
                sh 'mvn test'
            }
        }
        stage('Deploy') {
            // 部署到远程服务器
            steps {
                script {
                    // StrictHostKeyChecking=no 表示不检查远程主机的公钥 建议配置好ssh的免密登录
                    // Step 1: 传输文件到远程服务器 scp -v 可以查看文件传输的进度
                    sh """
                        scp -v -o StrictHostKeyChecking=no target/${JAR_FILE} ${SERVER_USER}@${SERVER_IP}:${TARGET_DIR}
                    """

                    // Step 2: 杀死已存在的进程
                    def killStatus = sh(script: """
                        ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} 'pgrep -f ${JAR_FILE} | xargs kill -9 || true'
                    """, returnStatus: true)

                    echo "Kill process exit status: ${killStatus}"

                    // Step 3: 启动新的进程
                    sh """
                        ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} 'nohup java -jar ${TARGET_DIR}/${JAR_FILE} > /dev/null 2>&1 &'
                    """
                }
            }
        }*/
    }

    /*post {
        always {
            // 每次构建结束后清理工作目录
            cleanWs()
        }
        success {
            echo 'Deployment finished successfully'
        }
        failure {
            echo 'Deployment failed'
        }
    }*/
}

