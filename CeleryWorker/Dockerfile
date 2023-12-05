FROM python:3.8-slim-buster

WORKDIR /

COPY . .

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

CMD ["celery", "-A", "celery_worker.celery_app", "worker", "--loglevel=info"]
