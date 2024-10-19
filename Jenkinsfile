pipeline {
    environment {
        IMAGE_NAME = "webapp"
        IMAGE_TAG = "1.0"  // Correction ici pour définir la balise (tag) de l'image
        APP_CONTAINER_PORT = "8085"
        APP_EXPOSED_PORT = "8085"
        DOCKERHUB_ID = "lionie"
        HOST_IP = "192.168.56.10"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
    }
    agent none
    stages {
        stage('Build image') {
            agent any
            steps {
                script {
                    sh 'docker build -f ./app/ic-webapp/Dockerfile -t ${DOCKERHUB_ID}/${IMAGE_NAME}:${IMAGE_TAG} ./app/ic-webapp'
                }
            }
        }
        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                    echo "Cleaning existing container if exist"
                    docker ps -a | grep -i $IMAGE_NAME && docker rm -f ${IMAGE_NAME}
                    docker run --name ${IMAGE_NAME} -d -p $APP_EXPOSED_PORT:$APP_CONTAINER_PORT ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    '''
                }
            }
        }
        stage('Test image') {
            agent any
            steps {
                script {
                    sh '''
                    curl -I http://${HOST_IP}:${APP_EXPOSED_PORT} | grep -i "200"
                    '''
                }
            }
        }
        stage('Clean container') {
            agent any
            steps {
                script {
                    sh '''
                       CONTAINER_ID=$(docker ps -aqf "name=$IMAGE_NAME")
                        if [ ! -z "$CONTAINER_ID" ]; then
                            docker stop $CONTAINER_ID || true
                            docker rm $CONTAINER_ID || true
                        fi  
                    '''
                }
            }
        }
        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                script {
                    sh '''
                    echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_ID --password-stdin
                    docker push ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }
         stage ('Prepare Ansible environment') {
          agent any         
          steps {
             script {
               sh '''
                  echo "Cleaning workspace before starting"
                  echo "ansible_host: 192.168.56.12" > app/ansible-ressources/host_vars/odoo_server.yml
                  echo "ansible_host: 192.168.56.11" > app/ansible-ressources/host_vars/ic_webapp_server.yml
                  echo "ansible_host: 192.168.56.11" > app/ansible-ressources/host_vars/pg_admin_server.yml
                  echo "host_pgadmin_ip: 192.168.56.11" >> app/ansible-ressources/host_vars/ic_webapp_server.yml
                  echo "host_odoo_ip: 192.168.56.12" >> app/ansible-ressources/host_vars/ic_webapp_server.yml

                        

               '''
             }
          }
        }
                  
        stage ("Deploy in PRODUCTION") {
            /* when { expression { GIT_BRANCH == 'origin/prod'} } */
            agent { docker { image 'registry.gitlab.com/robconnolly/docker-ansible:latest'  } }                     
            stages {
                stage ("PRODUCTION - Ping target hosts") {
                    steps {
                        script {
                            sh '''
                                apt update -y
                                apt install sshpass -y                            
                                export ANSIBLE_CONFIG=$(pwd)/app/ansible-ressources/ansible.cfg
                                ansible prod -m ping  -o
                            '''
                        }
                    }
                }                                                       
                stage ("PRODUCTION - Install Docker on all hosts") {
                    steps {
                        script {
                            timeout(time: 30, unit: "MINUTES") {
                                input message: "Etes vous certains de vouloir cette MEP ?", ok: 'Yes'
                            }                            

                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/app/ansible-ressources/ansible.cfg
                                ansible-playbook app/ansible-ressources/playbooks/install-docker.yml  -l odoo_server,pg_admin_server
                            '''                                
                        }
                    }
                }

               
            }
        } 
      
    }
}
