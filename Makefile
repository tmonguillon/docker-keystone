build:
	docker build -t openstack-keystone:master .
run:
	docker run -t -i -d --rm --hostname keystone -e ADMIN_PASSWORD=password --name keystone openstack-keystone:master
clean:
	docker rm -f keystone
purge:
	docker rmi openstack-keystone:master
exec:
	docker exec -t -i keystone sh
log:
	docker logs -f keystone
up:
	docker-compose up -d
down:
	docker-compose down
cexec:
	docker-compose exec keystone sh