docker volume create consul

docker run -d --restart=always --name=consul --net=host \
-v consul:/consul/data \
-e CONSUL_BIND_INTERFACE=eth0 \
consul agent -dev -client 0.0.0.0 -node db
