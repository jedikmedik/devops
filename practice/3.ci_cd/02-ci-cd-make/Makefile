SHELL:=/bin/bash
TIMESTAMP := $(shell date +%s)

## help: Display this help and exit
help: Makefile
	@echo "Choose a command to run:"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'

## clear: Сlear build artifacts
clear:
	@rm -rf vendor
	@echo "Build artifacts remove"


## build: Build application local
build:
	$(MAKE) clear

	@export $$(grep -v '^#' .env | xargs -d '\n') &&\
		bundle config build.nokogiri --use-system-libraries &&\
		bundle install --clean --without development --path vendor/bundle &&\
		bundle exec rake assets:precompile

	@echo "Build complete"


## deploy: Deploy application on remote server
deploy:

	$(MAKE) clear
	@export $$(grep -v '^#' .env | xargs -d '\n') &&\
		ssh $$HOST "mkdir -p /srv/www/xpaste/releases/$(TIMESTAMP);" &&\
		rsync -aH --no-perms --no-owner --no-group --omit-dir-times ./ $$HOST:/srv/www/xpaste/releases/$(TIMESTAMP) &&\
		ssh $$HOST "cd /srv/www/xpaste/releases/$(TIMESTAMP); \
		bundle config --local build.pg --with-pg="/usr/pgsql-9.6"; \
		bundle install --clean --without development --path vendor/bundle; \
		export $$(grep -v '^#' .env | xargs -d '\n'); bundle exec rake assets:precompile;" &&\
		ssh $$HOST "ln -nfs /srv/www/xpaste/releases/$(TIMESTAMP) /srv/www/xpaste/current" &&\
		ssh $$HOST "cd /srv/www/xpaste/releases/$(TIMESTAMP); export $$(grep -v '^#' .env | xargs -d '\n'); bundle exec rake db:migrate;" &&\
		ssh $$HOST "systemctl restart xpaste"
	@echo "Deploy complete"


## rollback: Rollback last deploy of application
rollback:

	@export $$(grep -v '^#' .env | xargs -d '\n') &&\
		ssh $$HOST 'ln -nfs $$(ls -trd /srv/www/xpaste/releases/*| tail -2| head -1) /srv/www/xpaste/current; rm -rf $$(ls -trd /srv/www/xpaste/releases/*| tail -1);'
	@echo "Deploy complete"
