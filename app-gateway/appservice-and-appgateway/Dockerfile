FROM golang:1.26.0-alpine3.23

WORKDIR /app

COPY . .


# Generate executable file 
RUN go build -o main .

EXPOSE 8080


# Execute the generated script
CMD [ "./main" ]