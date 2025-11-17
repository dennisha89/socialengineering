.PHONY: help install setup dev test clean docker-up docker-down deploy

# Default target
help:
	@echo "Available commands:"
	@echo "  make install       - Install Python dependencies"
	@echo "  make setup         - Initial setup (install + download models)"
	@echo "  make dev           - Run development server"
	@echo "  make test          - Run tests"
	@echo "  make test-cov      - Run tests with coverage"
	@echo "  make lint          - Run linters"
	@echo "  make format        - Format code with black"
	@echo "  make docker-up     - Start all Docker services"
	@echo "  make docker-down   - Stop all Docker services"
	@echo "  make docker-logs   - View Docker logs"
	@echo "  make clean         - Clean cache and temporary files"
	@echo "  make deploy        - Deploy to production"

# Installation
install:
	pip install -r requirements.txt

setup: install
	python -m spacy download en_core_web_trf
	python -m spacy download en_core_web_sm
	python -m nltk.downloader punkt vader_lexicon stopwords
	mkdir -p models data logs
	cp .env.example .env
	@echo "Setup complete! Please edit .env with your API keys"

# Development
dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

worker:
	celery -A app.celery_app worker --loglevel=info

scheduler:
	celery -A app.celery_app beat --loglevel=info

# Testing
test:
	pytest tests/ -v

test-cov:
	pytest tests/ --cov=app --cov-report=html --cov-report=term

test-integration:
	pytest tests/integration/ -v

# Code quality
lint:
	flake8 app tests
	pylint app tests
	mypy app

format:
	black app tests
	isort app tests

# Docker
docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-restart:
	docker-compose restart

# Database
db-migrate:
	alembic upgrade head

db-rollback:
	alembic downgrade -1

db-reset:
	docker-compose down -v
	docker-compose up -d postgres
	sleep 5
	alembic upgrade head

# Monitoring
metrics:
	curl http://localhost:8000/metrics

health:
	curl http://localhost:8000/health

# MLflow
mlflow-ui:
	mlflow ui --host 0.0.0.0 --port 5000

# Airflow
airflow-init:
	docker-compose run airflow-webserver airflow db init
	docker-compose run airflow-webserver airflow users create \
		--username admin \
		--firstname Admin \
		--lastname User \
		--role Admin \
		--email admin@example.com

# Data
download-sample-data:
	python scripts/download_sample_data.py

preprocess-data:
	python scripts/preprocess_data.py

# Training
train-embeddings:
	python scripts/train_embeddings.py

train-clustering:
	python scripts/train_clustering.py

train-all:
	python scripts/train_all_models.py

# Deployment
deploy-staging:
	kubectl apply -f k8s/staging/

deploy-production:
	kubectl apply -f k8s/production/

# Utilities
clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.coverage" -delete
	rm -rf htmlcov/
	rm -rf .pytest_cache/
	rm -rf .mypy_cache/
	rm -rf dist/
	rm -rf build/
	rm -rf *.egg-info

clean-models:
	rm -rf models/*.pt
	rm -rf models/*.pkl

backup-db:
	docker-compose exec postgres pg_dump -U mlops ml_pipeline > backup_$(shell date +%Y%m%d_%H%M%S).sql

restore-db:
	@echo "Usage: make restore-db BACKUP=backup_file.sql"
	docker-compose exec -T postgres psql -U mlops ml_pipeline < $(BACKUP)

# Documentation
docs:
	mkdocs serve

docs-build:
	mkdocs build

# Version
version:
	@echo "Current version: $(shell cat VERSION)"

bump-version:
	@echo "Current version: $(shell cat VERSION)"
	@read -p "New version: " version; echo $$version > VERSION
	git add VERSION
	git commit -m "Bump version to $$version"
	git tag -a v$$version -m "Version $$version"

# All-in-one commands
all: clean install test

dev-all:
	make -j3 dev worker scheduler

docker-all: docker-down docker-up docker-logs

# CI/CD
ci: lint test

cd: deploy-production
