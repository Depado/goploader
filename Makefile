version = 1.0.2
export GO111MODULE=on
export CGO_ENABLED=0
export VERSION=$(shell git describe --abbrev=0 --tags 2> /dev/null || echo "0.1.0")
export TAG=$VERSION
export BUILD=$(shell git rev-parse HEAD 2> /dev/null || echo "undefined")

.PHONY: all clients servers release clean

all:
	go build -o client/client github.com/Depado/goploader/client
	go build -o server/server github.com/Depado/goploader/server

clients:
	-mkdir -p releases/clients
	-mkdir -p releases/servers
	-rm releases/clients/*
	gox -output="releases/clients/client_{{.OS}}_{{.Arch}}" github.com/Depado/goploader/client
	tar czf releases/servers/clients.tar.gz releases/clients

servers:
	-mkdir -p releases/servers
	-mkdir goploader-server
	rice embed-go -i=github.com/Depado/goploader/server
	go build -o goploader-server/server-standalone github.com/Depado/goploader/server
	tar czf releases/servers/server-standalone_amd64.tar.gz goploader-server
	rm -r goploader-server/*
	rice clean -i=github.com/Depado/goploader/server
	cp -r server/assets/ goploader-server/
	cp -r server/templates/ goploader-server/
	go build -o goploader-server/server github.com/Depado/goploader/server
	tar czf releases/servers/server_amd64.tar.gz goploader-server/
	rm -r goploader-server/*
	rice embed-go -i=github.com/Depado/goploader/server
	GOARCH=arm go build -o goploader-server/server-standalone github.com/Depado/goploader/server
	tar czf releases/servers/server-standalone_arm.tar.gz goploader-server
	rm -r goploader-server/*
	rice clean -i=github.com/Depado/goploader/server
	cp -r server/assets/ goploader-server/
	cp -r server/templates/ goploader-server/
	GOARCH=arm go build -o goploader-server/server github.com/Depado/goploader/server
	tar czf releases/servers/server_arm.tar.gz goploader-server/
	-rm -r goploader-server

release: clients servers
	tar czf servers.tar.gz releases/servers/
	mv servers.tar.gz releases/servers/

docker:
	docker build -t gpldr:latest -t gpldr:$(BUILD) -f Dockerfile .

ensure-rice:
	if [ ! -f server/rice-box.go ]; then rice embed-go -i=github.com/Depado/goploader/server; fi

ensure-norice:
	if [ -f server/rice-box.go ]; then rm server/rice-box.go; fi

.PHONY: snapshot
snapshot: ## Create a new snapshot release
	goreleaser --snapshot --skip-publish --rm-dist

clean:
	-rm -r releases/
	-rm server/rice-box.go
	-rm -r goploader-server
