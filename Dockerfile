FROM python:3.8-slim-buster

ENV FLASK_APP pyshop.py
ENV FLASK_CONFIG development

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /code/

COPY Pipfile Pipfile.lock /code/
RUN pip install pipenv && pipenv install --system

COPY . /code/

EXPOSE 5000
