FROM python:3.8

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /usr/src/app
RUN --mount=type=bind,source=Pipfile,target=Pipfile \
    --mount=type=bind,source=Pipfile.lock,target=Pipfile.lock \
    pip install pipenv && pipenv install --system

COPY pyshop.py config.py ./
COPY app app

EXPOSE 5000