FROM ubuntu:latest

USER root

WORKDIR /app

COPY . .

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install flask && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install -r requirements.txt

ENV APP_ENV=production
ENV DATABASE_URL=sqlite:///app.db
ENV SECRET_KEY=my-super-secret-key-12345

EXPOSE 8080

CMD python3 app.py
