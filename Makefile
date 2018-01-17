build:
	docker build -t openstack-keystone .
run:
	docker run -t -i -d --hostname keystone -e ADMIN_PASSWORD=password --name keystone openstack-keystone
clean:
	docker rm -f keystone
exec:
	docker exec -t -i keystone sh
log:
	docker logs -f keystone
