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
        stage('Install Tools&initialize') {
            steps {
                script{
                    
                    // 确保 Homebrew 路径已添加到环境变量 PATH 中
                     withEnv(["PATH+BREW=/opt/homebrew/bin"]){
                        echo "Home 安装检查"
                        def hombrew_installed = sh(script: "brew --version", returnStatus: true)
                        if(hombrew_installed != 0){
                            echo "Installing with Homebrew..."
                            sh '''#!/bin/bash
                            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
                            '''
                        }else{
                            echo "Homebrew is already installed."
                        }
                     
                        echo "Mise 安装检查"
                        def mise_installed = sh(script: "mise --version", returnStatus: true)
                        if(mise_installed != 0){
                            echo "Installing with Mise..."
                            sh 'brew install mise'
                        }else{
                            echo "Mise is already installed."
                        }
                        
                        echo "Cocoapods 安装检查"
                        def cocoapods_installed = sh(script: "pod --version", returnStatus: true)
                        if(cocoapods_installed != 0){
                            echo "Installing with Cocoapods..."
                            sh 'brew install cocoapods'
                        }else{
                            echo "Cocoapods is already installed."
                        }

                        //Tuist 安装
                        echo "Tuist 安装检查"
                        def tuist_installed = sh(script: "which tuist", returnStatus: true)
                        if(tuist_installed != 0){
                            echo "Installing Tuist..."
                            sh 'mise install tuist'

                            // 添加 tuist 到 PATH 中，确保后续可以使用
                            echo "Adding Tuist to PATH"
                            sh '''#!/bin/bash
                            export PATH="$PATH:/opt/homebrew/bin"
                            '''
                            // 重新加载环境变量
                            sh 'mise use tuist@latest'
                        }else{
                            echo "Tuist is already installed."
                        }
                        
                        sh 'echo "✅DevivedData 삭제"'
                        sh 'rm -rf ~/Library/Developer/Xcode/DerivedData/*'

                        //.xcodeproj .xcworkspace삭제
                        sh 'echo "✅Delete .xcodeproj,.xcworkspace"'
                        sh 'rm -rf *xcodeproj *xcworkspace'

                        sh 'echo "✅Tuist Clean"'
                        sh 'tuist clean'

                        sh 'tuist generate'
                        
                        sh 'echo "✅pod install"'
                        sh 'pod install'
                        sh 'echo "🎉setup completed"'
                    }
                }
            }
        }
    
    }

}
