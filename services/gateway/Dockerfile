FROM golang:1.21-alpine3.19 AS build

WORKDIR /app

# Install protoc
RUN apk add --no-cache protobuf-dev
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

COPY proto proto
COPY services/gateway .

RUN go mod download
RUN protoc --go_out=proto --go-grpc_out=proto proto/*.proto
RUN go build -o main .

##################################################################

FROM alpine:3.19

WORKDIR /app

# Copy only necessary files from the build stage
COPY --from=build /app/main .

EXPOSE 8080

CMD ["./main"]