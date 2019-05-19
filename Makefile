.PHONY: all prepare_db build run start restart stop migrate create_db drop_db down kill logs ps rspec

all: .env build prepare_db run

prepare_db: create_db migrate

.env:
	[[ ! -f ".env"  ]] && cp -n .env.sample .env
	@echo "\nPlease update you .env file with proper values."

build:
	@echo "\nBuilding kingsly\n"
	docker-compose build

run:
	@echo "\nDaemonising docker containers\n"
	docker-compose up -d

start:
	@echo "\nStarting docker containers\n"
	docker-compose start

restart: stop build run

stop:
	@echo "\nStoping docker containers\n"
	docker-compose stop

migrate:
	@echo "\nRunning migrations\n"
	docker-compose run --rm kingsly-server bash -c "source .env ; rake db:migrate"

create_db:
	@echo "\nCreate DB\n"
	docker-compose run --rm kingsly-server bash -c "source .env ; rake db:create"

drop_db: stop
	@echo "\nCleaning DB\n"
	echo y | docker-compose rm -v postgres

down: kill
	@echo "\nRunning docker-compose down\n"
	docker-compose down

kill:
	@echo "\nRemoving daemonised containers\n"
	docker-compose kill
	docker ps | grep kings | awk '{ print $$1 }' | xargs -I{} docker kill {}

logs:
	@echo "\nGetting logs of kingsly-server container\n"
	docker-compose logs -f kingsly-server

ps:
	docker-compose ps

rspec: down
	docker-compose run --rm kingsly-server \
	  bash -c "RAILS_ENV=test; bundle exec rake db:drop db:create; bundle exec rake db:migrate; bundle exec rspec spec/"
	make down
