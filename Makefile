.PHONY: help install migrate run db-shell worker beat shell test clean build-apk

help:
	@echo "Available commands:"
	@echo "  install      Install dependencies"
	@echo "  migrate      Run database migrations"
	@echo "  run          Start development server"
	@echo "  db-shell     Open database shell"
	@echo "  worker       Start Celery worker"
	@echo "  beat         Start Celery beat"
	@echo "  shell        Open Django shell"
	@echo "  test         Run tests"
	@echo "  clean        Clean build artifacts"
	@echo "  build-apk    Build User App Release APK"

install:
	pip install -r requirements/development.txt

migrate:
	python manage.py migrate

run:
	daphne config.asgi:application --bind 0.0.0.0 --port 8000

db-shell:
	python manage.py dbshell

worker:
	celery -A config worker -l info

beat:
	celery -A config beat -l info

shell:
	python manage.py shell

test:
	python manage.py test

clean:
	cd parking_user_app && flutter clean
	cd parking_officer_app && flutter clean

build-apk:
	cd parking_user_app && flutter build apk --release
