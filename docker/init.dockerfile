FROM golang:latest
WORKDIR /init
COPY /init .
RUN go mod tidy
CMD ["go", "run", "./cmd"]