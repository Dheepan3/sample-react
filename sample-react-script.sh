#!/bin/bash
set -e

# Define variables for deployment
REPO_PATH="/home/dheepan-s/sample-react-gapp"
APP_NAME="sample-react-web"
DOCKER_IMAGE="sample-react-web:latest"
DOCKER_CONTAINER="sample-react-web:latest"
HOST_PORT=3001
CONTAINER_PORT=3001

# Define Google Chat webhook URL
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAAbD_B3UM/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=YbT6wea9MfTpjpRng2TRxPgSWc3AqVRW0rySnlM1X8w"

# Function to send a notification to Google Chat
send_notification() {
    STATUS=$1  # Status of the deployment: Started, Successful, or Failed
    BRANCH=$2  # Branch being deployed
    COMMITTER=$3  # Name of the committer
    COMMIT_MSG=$4  # Commit message

    # Define the JSON payload
    read -r -d '' PAYLOAD <<EOF
    {
      "cards": [
        {
          "header": {
            "title": "QA Deployment Notification",
            "subtitle": "Deployment $STATUS for $APP_NAME",
            "imageStyle": "AVATAR"
          },
          "sections": [
            {
              "widgets": [
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eApplication:\u003c/b\u003e $APP_NAME"
                  }
                },
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eEnvironment:\u003c/b\u003e QA"
                  }
                },
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eBranch:\u003c/b\u003e $BRANCH"
                  }
                },
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eCommited-By:\u003c/b\u003e $COMMITTER"
                  }
                },
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eCommit-Message:\u003c/b\u003e $COMMIT_MSG"
                  }
                },
                {
                  "textParagraph": {
                    "text": "\u003cb\u003eStatus:\u003c/b\u003e $STATUS"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
EOF

    # Send the POST request to Google Chat
    curl -X POST "${WEBHOOK_URL}" \
        -H "Content-Type: application/json" \
        -d "${PAYLOAD}"
}

# Navigate to the repository
cd $REPO_PATH

# Notify deployment started
send_notification "Started" "$1" "$(git log -1 --pretty=format:'%an')" "$(git log -1 --pretty=format:'%s')"

# Git operations
git fetch
git checkout $1
git pull

# Function to clean up old containers and images
cleanup() {
    echo "Cleaning up old containers and images..."
    if [ "$(docker ps -aq -f name=$DOCKER_CONTAINER)" ]; then
        docker stop $DOCKER_CONTAINER
        docker rm $DOCKER_CONTAINER
    fi
}

# Function to build the Docker image
build() {
    echo "Building the Docker image..."
    docker build -t $DOCKER_IMAGE .
}

# Function to run the Docker container
run() {
    echo "Running the Docker container..."
    docker run -d -p $HOST_PORT:$CONTAINER_PORT --name $DOCKER_CONTAINER $DOCKER_IMAGE
}

# Main deployment function
deploy() {
    cleanup
    build
    run
}

# Execute the deployment and handle errors
if deploy; then
    # Notify successful deployment
    send_notification "Successful" "$1" "$(git log -1 --pretty=format:'%an')" "$(git log -1 --pretty=format:'%s')"
    echo "Deployment complete. Your application is running at http://localhost:$HOST_PORT"
else
    # Notify failed deployment
    send_notification "Failed" "$1" "$(git log -1 --pretty=format:'%an')" "$(git log -1 --pretty=format:'%s')"
    echo "Deployment failed."
    exit 1
fi

# Clean up unused Docker resources
#docker system prune -af
