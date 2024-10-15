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
                    sh 'docker build -f ./app/Dockerfile -t ${DOCKERHUB_ID}/${IMAGE_NAME}:${IMAGE_TAG} ./app'  // Correction du chemin ici
                }
            }
        }
       /* stage('Scan Image with SNYK') {
            agent any
            environment {
                SNYK_TOKEN = credentials('snyk_token')
            }
            steps {
                script {
                    sh '''
                    echo "Starting Image scan ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ..."
                    echo There is Scan result :
                    SCAN_RESULT=$(docker run --rm -e SNYK_TOKEN=$SNYK_TOKEN -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/app snyk/snyk:docker snyk test --docker $DOCKERHUB_ID/$IMAGE_NAME:$IMAGE_TAG --json || if [[ $? -gt "1" ]]; then echo -e "Warning, you must see scan result\n"; false; elif [[ $? -eq "0" ]]; then echo "PASS: Nothing to Do"; elif [[ $? -eq "1" ]]; then echo "Warning, passing with something to do"; else false; fi)
                    echo "Scan ended"
                    '''
                }
            }
        }*/
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
    }
}
