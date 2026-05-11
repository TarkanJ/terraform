# Terraform & YAML files

- 👍 created a group of containers => images from: https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
- 👍 simulated 2 different environments (DEV = 2 replicas / PROD = 3 replicas)  
- 👍 listening replicas for connections on port :30711
- 👍 created load balancer for groups DEV & PROD
- 😵 created a cronjob that will call out the load balancer
- periodically and will print the result on stdout.(will be finished later)
- 😓 terraform file just roughly created...
- 😊 screenshots with each replicas, and pods in directory...
