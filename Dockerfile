
FROM python:3.6-alpine

LABEL maintainer="Adjimi Lionelle"

WORKDIR /opt

COPY app /opt

RUN pip install --no-cache-dir Flask

EXPOSE 8080

ENV ODOO_URL=""
ENV PGADMIN_URL=""

ENTRYPOINT ["python", "app.py"]