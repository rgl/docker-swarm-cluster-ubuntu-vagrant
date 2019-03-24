FROM golang:1.12.1-alpine as builder
WORKDIR /go/src/go-info
COPY main.go .
RUN CGO_ENABLED=0 go build

FROM scratch
COPY --from=builder /go/src/go-info/go-info .
WORKDIR /
EXPOSE 8000
ENTRYPOINT ["/go-info"]
