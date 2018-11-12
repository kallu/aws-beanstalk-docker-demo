# aws-beanstalk-docker-demo
How to run docker container on AWS Beanstalk

### 1. Local development/debug
  * Build <code>docker build -t web_app .</code>
  * Run <code>docker container run --detach -p 80:80 web_app</code>
  * Test http://localhost/
  * Debug
  
        docker container ps
        docker container attach --sig-proxy=false CONTAINER_ID
        docker container exec -i -t CONTAINER_ID /bin/bash
        
  * Kill <code>docker container kill CONTAINER_ID</code>

### 2. Upload working container to ECR
  * Create ECR repository<br>

        aws cloudformation create-stack --stack-name web-app-repo --template-body file://ecr.yaml
        aws cloudformation describe-stacks --stack-name web-app-repo
        ...
            "Outputs": [
                {
                    "Description": "ECR ARN", 
                    "OutputKey": "RepositoryArn", 
                    "OutputValue": "arn:aws:ecr:eu-west-1:123456789012:repository/web-app-repo"
                }
            ],
        ...
 
  * Login to ECR <code>$(aws ecr get-login --no-include-email --region eu-west-1)</code>
  * Tag containers
  
        docker tag web_app:latest 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo:latest
        docker tag web_app:latest 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo:1.0
      
  * Push containers to ECR <code>docker push</code>
  * List local and ECR images
  
        docker images
        docker images 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo

### 3. Build AWS Infrastructure

   * VPC and subnets for hosting application infrastructure.

         aws cloudformation create-stack --stack-name web-app-vpc --template-body file://vpc-1nat.yaml
         # NOTE: If you want dedicated NAT-GW for each AZ, use vpc.yaml -template

   * S3 bucket for Beanstalk application bundle.<br><br>
If you don't already have s3logs-ACCOUNTID-REGION -bucket for storing S3 access logs,
you must create one before creating bucket for application bundle. When S3 logging bucket is ready,
create a bucket for Beanstalk application bundle.

         aws cloudformation create-stack --stack-name s3logs --template-body file://s3logs.yaml
         aws cloudformation create-stack --stack-name web-app-s3 --template-body file://s3bucket.yaml \
         --parameters ParameterKey=bucketname,ParameterValue=web-app-123456789012

### 4. Build Beanstalk application bundle and upload to S3

        zip -r web-app.zip Dockerrun.aws.json .ebextensions
        aws s3 cp web-app.zip s3://web-app-123456789012/web_app.zip

NOTE1: Remember to edit Dockerrun.aws.json to point your container image and tag in your ECR -repo. See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_v2config.html

NOTE2: .ebextensions is where you put all custom configuration you want to have on docker hosts run by Beanstalk. This can be extra software installed on EC2 or Beanstalk configuration options etc. See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/ebextensions.html

### 5. Create Beanstalk application and run your container

         aws cloudformation create-stack --stack-name web-app-eb --template-body file://beanstalk.yaml \
         --parameters ParameterKey=keyname,ParameterValue=value

### 6. Debug Beanstalk container

Add here how to open a shell session on EC2 with SSM Session Manager.

### 7. Shared persistent storage for containers

This is left for reader to implement :-)

* There is placeholder for mounting EFS on EC2 at `.ebextensions/ef-mount.config`

* To mount host volumes on containers you must define volume(s)

        "volumes": [
            {
              "name": "app",
              "host": {
                "sourcePath": "/var/app/current/dist"
              }
            }
        ]

* And mount point in `containerDefinition` 

        "mountPoints": [
          {
            "sourceVolume": "app",
            "containerPath": "/var/www/html",
            "readOnly": true
          }
        ]

* Or you can simply mount all volumes from another container with `volumesFrom`

* See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_v2config.html