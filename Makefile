test:
	docker-compose run --rm test

lint:
	docker-compose run --rm lint

.PHONY: lint test

