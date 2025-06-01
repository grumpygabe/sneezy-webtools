FROM python:3.11-slim

# Install Node.js
RUN apt-get update && apt-get install -y \
    curl \
    inotify-tools \
    procps \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y netcat-traditional \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory and install dependencies
COPY . /app
WORKDIR /app
RUN pip install --no-cache-dir -r /app/src/requirements.txt
WORKDIR /app/src
RUN npm install && npm install -g vite && npm install -g serve && npx update-browserslist-db@latest && npm install -g svgo
# Expose port for the web server
EXPOSE 5000

# Run the startup script
RUN chmod +x /app/start.sh
CMD ["/app/start.sh"]