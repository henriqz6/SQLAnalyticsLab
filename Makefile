.PHONY: up reset test verify plans shell down clean

up:
	docker compose up -d mysql

reset:
	./scripts/reset.sh

test:
	./scripts/run-tests.sh

verify:
	./scripts/run-all.sh

plans:
	./scripts/collect-plans.sh

shell:
	docker compose exec mysql mysql -uanalytics -panalytics_password sql_analytics_lab

down:
	docker compose down

clean:
	docker compose down -v
