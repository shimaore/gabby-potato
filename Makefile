#
# This is a generic Makefile. It uses contents from package.json
# to build Docker images.
#
NAME=`jq -r .docker_name package.json`
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

local: image
	DEBUG='*,-esl:*,esl:response,-engine.io-client:*,-socket.io-parser' coffee local/app.coffee.md &
	docker run --rm --env-file=$$PWD/local/env --net host --name gabby-potato-test-2 ${NAME}:${TAG}

shell:
	docker exec -t -i gabby-potato-test-2 /bin/bash
