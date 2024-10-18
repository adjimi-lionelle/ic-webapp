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
                    sh 'docker build -f ./app/Dockerfile -t ${DOCKERHUB_ID}/${IMAGE_NAME}:${IMAGE_TAG} ./app'
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
          environment {
            VAULT_KEY = credentials('vault_key')
            PRIVATE_KEY = credentials('private_key')
            PUBLIC_KEY = credentials('public_key')
            VAGRANT_PASSWORD = credentials('vagrant_password')
          }          
          steps {
             script {
               sh '''
                  echo "Cleaning workspace before starting"
                  rm -f vault.key id_rsa id_rsa.pub password
                  echo "Generating vault key"
                  echo -e $VAULT_KEY > vault.key
                  echo "Generating private key"
                  cp $PRIVATE_KEY  id_rsa
                  chmod 400 id_rsa vault.key
                  #echo "Generating public key"
                  #echo -e $PUBLIC_KEY > id_rsa.pub
                  #echo -e $VAGRANT_PASSWORD > password
                  echo "Generating host_vars for EC2 servers"
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > sources/ansible-ressources/host_vars/odoo_server_dev.yml
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > sources/ansible-ressources/host_vars/ic_webapp_server_dev.yml
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > sources/ansible-ressources/host_vars/pg_admin_server_dev.yml
                  echo "Generating host_pgadmin_ip and  host_odoo_ip variables"
                  echo "host_odoo_ip: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" >> sources/ansible-ressources/host_vars/ic_webapp_server_dev.yml
                  echo "host_pgadmin_ip: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" >> sources/ansible-ressources/host_vars/ic_webapp_server_dev.yml

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
                                ansible-playbook app/ansible-ressources/playbooks/install-docker.yml --vault-password-file vault.key  -l odoo_server,pg_admin_server
                            '''                                
                        }
                    }
                }

                stage ("PRODUCTION - Deploy pgadmin") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/app/ansible-ressources/ansible.cfg
                                ansible-playbook app/ansible-ressources/playbooks/deploy-pgadmin.yml --vault-password-file vault.key  -l pg_admin
                            '''
                        }
                    }
                }
                stage ("PRODUCTION - Deploy odoo") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/app/ansible-ressources/ansible.cfg
                                ansible-playbook app/ansible-ressources/playbooks/deploy-odoo.yml --vault-password-file vault.key  -l odoo
                            '''
                        }
                    }
                }

                stage ("PRODUCTION - Deploy ic-webapp") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/app/ansible-ressources/ansible.cfg
                                ansible-playbook app/ansible-ressources/playbooks/deploy-ic-webapp.yml --vault-password-file vault.key  -l ic_webapp

                            '''
                        }
                    }
                }
            }
        } 
      
    }
}
