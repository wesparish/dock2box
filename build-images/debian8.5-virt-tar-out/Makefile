NAME=debian8.5-virt-tar-out
REPO=wesparish
REG=

all: push

clean:
	docker rmi ${NAME} &>/dev/null || true

build: clean										   
	docker login
	docker build --pull=true --no-cache -t $(REG)$(REPO)/$(NAME):latest .

push: build
	docker push $(REG)$(REPO)/$(NAME):latest
