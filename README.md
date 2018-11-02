# aws-beanstalk-docker-demo
How to run docker container on AWS Beanstalk

Build it:
`docker build -t web_app .`

Run it:
`docker container run --detach -p 80:80 web_app`

Test it:
http://localhost/
