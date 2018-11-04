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

3. Build Beanstalk package

4. Run container on Beanstalk

5. Debug Beanstalk container
