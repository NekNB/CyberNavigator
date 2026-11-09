FROM golang:1.26.2-alpine3.22 AS builder
WORKDIR /build
COPY /workers/fill/go.mod /workers/fill/go.sum ./
RUN go mod download -x
CMD ["go", "run", "./cmd"]

COPY /workers/fill/cmd ./cmd
COPY /workers/fill/internal ./internal

RUN go build -o	 ./fill-worker ./cmd

FROM alpine:latest

WORKDIR /root/
COPY --from=builder /build/fill-worker .

ENTRYPOINT [ "/root/fill-worker" ] 
