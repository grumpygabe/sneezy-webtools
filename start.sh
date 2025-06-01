#!/bin/bash

# Function to build and serve
build_and_serve() {
    
    # Wait for database
    echo "Waiting for database to be ready..."
    while ! nc -z sneezy-db 3306; do
        echo "Database not ready, waiting..."
        sleep 2
    done
    echo "Database is ready!"

    echo "Running map_gen.py..."
    cd /app/src
    python map_gen.py
    echo "Optimizing map svg..."
    npx svgo assets/map.svg -o assets/optimized-map.svg
    echo "Building Vite project..."
    npm run build
    
    # Kill existing serve process if running
    pkill -f "serve -s ../dist -l 5000" || true
    
    echo "Starting web server..."
    serve -s ../dist -l 5000 &
    SERVE_PID=$!
}

# Function to monitor version.txt
monitor_trigger_file() {
    local trigger_file="/app/lib/version.txt"
    local last_mtime=""
    
    mkdir -p /app/lib
    
    # Create file if it doesn't exist
    if [ ! -f "$trigger_file" ]; then
        echo "Initial" > "$trigger_file"
    fi
    
    echo "Monitoring $trigger_file for changes..."
    
    while true; do
        if [ -f "$trigger_file" ]; then
            current_mtime=$(stat -c %Y "$trigger_file" 2>/dev/null || echo "0")
            
            if [ -n "$last_mtime" ] && [ "$current_mtime" != "$last_mtime" ]; then
                echo "Detected change in trigger file, rebuilding..."
                build_and_serve
                sleep 2
            fi
            
            last_mtime="$current_mtime"
        fi
        
        sleep 1  # Check every second
    done
}

# Initial build and serve
build_and_serve

# Start monitoring in background
monitor_trigger_file &
MONITOR_PID=$!

# Keep the main process alive and monitor serve process
while true; do
    sleep 10
    # Check if serve process is still running
    if ! pgrep -f "serve -s ../dist -l 5000" > /dev/null; then
        echo "Serve process died, restarting..."
        cd /app/src
        serve -s ../dist -l 5000 &
    fi
done