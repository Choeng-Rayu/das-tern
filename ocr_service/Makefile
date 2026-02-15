.PHONY: install install-dev test run lint clean

install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

test:
	pytest tests/ -v

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

lint:
	python -m py_compile app/main.py

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage htmlcov
