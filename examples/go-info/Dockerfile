FROM golang:1.8.3-alpine as builder
WORKDIR /go/src/go-info
COPY main.go .
RUN go build

FROM alpine:3.6
COPY --from=builder /go/src/go-info/go-info .
WORKDIR /
EXPOSE 8000
ENTRYPOINT ["/go-info"]
