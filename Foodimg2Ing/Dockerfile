FROM python:3.8.13-slim-buster

WORKDIR /

COPY . .

WORKDIR /data

RUN apt-get update && apt-get install -y curl

RUN curl -O https://dl.fbaipublicfiles.com/inversecooking/modelbest.ckpt > modelbest.ckpt
RUN curl -O https://dl.fbaipublicfiles.com/inversecooking/ingr_vocab.pkl > ingr_vocab.pkl
RUN curl -O https://dl.fbaipublicfiles.com/inversecooking/instr_vocab.pkl > instr_vocab.pkl

WORKDIR /
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "--timeout", "90", "Foodimg2Ing:app"]
