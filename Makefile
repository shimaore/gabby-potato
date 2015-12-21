#
# This is a generic Makefile. It uses contents from package.json
# to build Docker images.
#
NAME=shimaore/`jq -r .name package.json`
TAG=`jq -r .version package.json`

image:
	# Compile CoffeeScript into JavaScript
	docker build -t ${NAME}:${TAG} .
	if [ -n "${REGISTRY}" ]; then docker tag -f ${NAME}:${TAG} ${REGISTRY}/${NAME}:${TAG}; fi

tests:
	npm test

push: image
	if [ -n "${REGISTRY}" ]; then docker push ${REGISTRY}/${NAME}:${TAG}; fi
	docker push ${NAME}:${TAG}
	if [ -n "${REGISTRY}" ]; then docker rmi ${REGISTRY}/${NAME}:${TAG}; fi
	docker rmi ${NAME}:${TAG}

dev: image
	docker kill gabby-potato-test-1 ; docker rm gabby-potato-test-1 ; DEBUG='*' npm test ;
	## Without container.remove() you can still do:
	# docker export gabby-potato-test-1 | tar xOvf - opt/gabby-potato/log/server.log ; \
	# docker export gabby-potato-test-1 | tar xOvf - opt/gabby-potato/log/freeswitch.log ; \
	# docker rm gabby-potato-test-1
