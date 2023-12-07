FROM python:3.8.13-slim-buster

WORKDIR .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "--timeout", "90", "Foodimg2Ing:app"]