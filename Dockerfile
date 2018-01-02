FROM bamos/openface:latest

RUN apt update && apt install -y vim

ADD photos /photos/
ADD recognition /app/
RUN chmod +x /app/*
