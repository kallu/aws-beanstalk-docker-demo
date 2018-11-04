# aws-beanstalk-docker-demo
How to run docker container on AWS Beanstalk

1. Local development/debug
  * Build <code>docker build -t web_app .</code>
  * Run <code>docker container run --detach -p 80:80 web_app</code>
  * Test http://localhost/
  * Debug<pre><code>docker container ps
    docker container attach --sig-proxy=false CONTAINER_ID
    docker container exec -i -t CONTAINER_ID /bin/bash</code></pre>
  * Kill <code>docker container kill CONTAINER_ID</code>

2. Upload working container to ECR

  * Create ECR repository<pre><code>
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
  </code></pre>NOTE: Your repository in above example is `123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo`
  * Login to ECR <code>$(aws ecr get-login --no-include-email --region eu-west-1)</code>
  * Tag containers <pre><code>docker tag web_app:latest 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo:latest
  docker tag web_app:latest 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo:1.0<code><pre>
  * Push containers to ECR <code>docker push</code>
  * List local and ECR images <pre><code>docker images
  docker images 123456789012.dkr.ecr.eu-west-1.amazonaws.com/web-app-repo<code></pre>

3. Build Beanstalk package

4. Run container on Beanstalk

5. Debug Beanstalk container
