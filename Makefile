
KEYSTONE_BRANCH=mitaka-eol

build:
	docker build --build-arg KEYSTONE_BRANCH=$(KEYSTONE_BRANCH) -t openstack-keystone .
run:
	docker run -t -i -d --rm --hostname keystone -e ADMIN_PASSWORD=password --name keystone openstack-keystone
clean:
	docker rm -f keystone
exec:
	docker exec -t -i keystone sh
log:
	docker logs -f keystone
