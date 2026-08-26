# Use an official, lightweight web server as a starting point
FROM nginx:alpine

# Copy our HTML file into the web server's directory
COPY sample.html /usr/share/nginx/html/

# The minimal alpine image doesn't have curl, so we install it for the healthcheck
RUN apk add --no-cache curl

# Tell Docker how to test if the container is healthy
# It will check every 30 seconds, wait 5 seconds for a response, and retry up to 3 times [1]
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost/sample.html || exit 1

# Tell the container to expose port 80 for web traffic
EXPOSE 80
