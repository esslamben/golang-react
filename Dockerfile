# Step 0 - Run the web build and get bundle
FROM node:11.12-alpine

RUN apk add --update \
    git \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY /web/frontend/package.json /web/frontend/yarn.lock ./

RUN yarn --pure-lockfile

COPY /web/frontend .

RUN yarn build

# Step 1 - Run go.rice to compile static/bundle assets & build go binary with said assets
FROM golang:1.12-alpine

RUN apk add --update \
    git \
    && rm -rf /var/cache/apk/*

COPY . /go/src/github/esslamb/golang-react

COPY --from=0 /app/build /go/src/github/esslamb/golang-react/web/frontend/build

WORKDIR /go/src/github/esslamb/golang-react/cmd/golang-react

RUN go get github.com/GeertJohan/go.rice github.com/GeertJohan/go.rice/rice && \
    go get ./... && \
    rice embed-go && \
    GOOS=linux GOARCH=amd64 go build -o golang-react.linux.x86_64 .

# Step 2 - Transfer binary and setup entry point and port to expose
FROM alpine:3.9

COPY --from=1 /go/src/github/esslamb/golang-react/cmd/golang-react/golang-react.linux.x86_64 /usr/bin/golang-react

ENTRYPOINT ["/usr/bin/golang-react"]