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
        aws s3 cp web-app.zip s3://web-app-123456789012/web-app.zip

NOTE1: Remember to edit Dockerrun.aws.json to point your container image and tag in your ECR -repo. See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_v2config.html

NOTE2: .ebextensions is where you put all custom configuration you want to have on docker hosts run by Beanstalk. This can be extra software installed on EC2 or Beanstalk configuration options etc. See https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/ebextensions.html

### 5. Create Beanstalk application and run your container

Create Elastic Beanstalk application and releated resources using Cloudformation. Note that template parameters are supplied in separate JSON -file rather than cmd-line parameters.
Please review content of `beanstalk-param.json` before creating the stack.

         aws --profile=kallu cloudformation create-stack --stack-name web-app-eb \
            --template-body file://beanstalk.yaml \
            --parameter file://beanstalk-param.json \
            --capabilities CAPABILITY_IAM

If everything went as planned you should have application listening at `EnvironmentURL` found from stack outputs.

        aws cloudformation describe-stacks --stack-name web-app-eb
        ...
            "Outputs": [
            ...
                {
                    "Description": "Environment URL", 
                    "ExportName": "web-app-eb-EnvironmentURL", 
                    "OutputKey": "EnvironmentURL", 
                    "OutputValue": "awseb-AWSEB-17TEWBQ2Y0G57-540870288.eu-west-1.elb.amazonaws.com"
                },
            ...
            ],
        ...

### 6. Debug Beanstalk container

Sometimes it could be useful for debugging purposes to have shell access to docker hosts and/or containers.
As you have AWS Systems Manager agent installed on Beanstalk Docker hosts from `.ebextensions/ssm-agent.config`
you can open an interactive shell session from AWS console navigating to AWS Systems Manager > Session Manager > Start a session. There you will have a list of all instances with SSM agent. Clicking “Start session” -button will open you an interactive shell in your browser window.

You can open a session also from cmd-line with AWS CLI. First be sure you have a recent version of cli and if necessary update it. You also need to [install session manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) to make this work. When ready, you can open a shell session with

        aws ssm start-session --target i-0deadbeef12345678

Note that

* You didn’t create any user accounts (or ssh keys) on host. Access is controlled in AWS IAM policies.

* EC2 instance had no SSH ports open in it’s security group.

* It will work as long as you can HTTPS to AWS API endpoints (i.e. internet).


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