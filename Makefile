# Configuration values
# RUNESTONE_HOST=courses.21-learning.com
include .env
export $(shell sed 's/=.*//' .env)

BUILD_DIR = build/$(TARGET_COURSE)
PUBLISH_DIR = build/$(TARGET_COURSE)

RUNESTONE_HOST=courses.${SITE_DOMAIN}
BASECOURSE = $(COURSE)-$(GITBRANCH)
THIS_COURSE = $(BASECOURSE)
# This is the base for all docker contexts related to runestone (Mandatory)
RUNESTONE_CONTEXT_BASE=runestone-backend

SSH_USER=root
SSH_PORT=22
SSH_HOST=$(RUNESTONE_HOST)

ifdef CUSTOM_SSH_USER
	SSH_USER=$(CUSTOM_SSH_USER)
endif
ifdef CUSTOM_SSH_PORT
	SSH_PORT=$(CUSTOM_SSH_PORT)
endif
ifdef CUSTOM_SSH_HOST
	SSH_HOST=$(CUSTOM_SSH_HOST)
endif

REMOTE=$(SSH_USER)@$(SSH_HOST)
SSH_OPTIONS=-o 'StrictHostKeyChecking no' -p $(SSH_PORT)
SSH = ssh $(SSH_OPTIONS) $(SSH_USER)@$(SSH_HOST)
SERVER_DIR=~/runestone-server
SERVER_COMPONENTS_DIR=/RunestoneComponents
COMPONENTS_DIR=~/runestone-components/
RSYNC_BASE_OPTIONS= -e 'ssh -o StrictHostKeyChecking=no -p $(SSH_PORT)' --progress
RSYNC_OPTIONS= $(RSYNC_BASE_OPTIONS) --exclude=.git --exclude=venv --exclude=ubuntu --exclude=stats --exclude=__pycache__ --exclude=junk --exclude=errors
RSYNC_KEEP=rsync $(RSYNC_OPTIONS)
RSYNC=rsync $(RSYNC_OPTIONS) --delete
TIME = $(shell date +%Y-%m-%d_%Hh%M)
DOTENV_FILE = .env.$(ENV_NAME)

REMOTE_DB_CONTAINER_ID = $(shell $(SSH) 'docker ps -qaf "name=db"')
REMOTE_RUNESTONE_CONTAINER_ID = $(shell $(SSH) 'docker ps -qaf "name=_runestone"') $(shell $(SSH) 'docker ps -qaf "name=runestone-1"')



VENV_DIR = $(shell pipenv --venv)



livehtml:
	watchmedo shell-command --patterns="*.rst;*.py;*.png;*.gif;*.jpg;*.jpeg" --recursive  --ignore-patterns='build' --command='make html' _sources

serve:
	runestone serve
	
build-all:
	runestone build --all && runestone deploy

html:
	runestone build && runestone deploy
	make patch-activecode

remote.%:
	$(SSH) 'cd $(SERVER_DIR) && make args.$* ARGS="$(REMOTE_ARGS)"'

push.build-all:
push.build:
push.%:
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz . $(REMOTE):$(SERVER_DIR)/books/$(THIS_COURSE) \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/$(THIS_COURSE) && cp -f pavement-dockerserver.py pavement.py'
	$(SSH) 'cd $(SERVER_DIR) && make course.$*.$(THIS_COURSE)'
	make update-skulpt
	$(SSH) 'cd $(SERVER_DIR)/books && sudo make update-activecode.$(THIS_COURSE)'

update-skulpt:
	$(SSH) 'cd $(SERVER_DIR) && sudo cp -rf skulpt-dist/* books/$(THIS_COURSE)/published/$(THIS_COURSE)/_static/'

show:
	@echo "Pushing ${BASECOURSE} to $(RUNESTONE_HOST) ..."

ssh:
	$(SSH)

