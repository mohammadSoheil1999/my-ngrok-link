#!/bin/bash

set -e

# === CONFIG ===
BASE_PATH="/home/user/projects"
WEBSITE_PATH="$BASE_PATH/website"
REPO_PATH="$BASE_PATH/my-ngrok-link"
HTML_FILE="index.html"   # change if needed
PORT=3000

# === START WEBSITE ===
echo "Starting website..."
cd "$WEBSITE_PATH" || { echo "Website path not found"; exit 1; }
npm run dev &

DEV_PID=$!
sleep 5

# === START NGROK ===
echo "Starting ngrok..."
pkill ngrok 2>/dev/null || true
ngrok http $PORT > /dev/null &

NGROK_PID=$!
sleep 5

# === GET NGROK URL ===
echo "Fetching ngrok URL..."
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [[ -z "$NGROK_URL" ]]; then
  echo "Failed to get ngrok URL"
  exit 1
fi

echo "Ngrok URL: $NGROK_URL"

# === UPDATE HTML IN REPO ===
echo "Updating HTML..."
cd "$REPO_PATH" || { echo "Repo path not found"; exit 1; }

sed -i "s|https://.*ngrok-free.app|$NGROK_URL|g" "$HTML_FILE"

# === PUSH TO GITHUB ===
echo "Pushing to GitHub..."
git add .
git commit -m "Update ngrok URL to $NGROK_URL" || echo "Nothing to commit"
git push

echo "Done!"
echo "Website PID: $DEV_PID | Ngrok PID: $NGROK_PID"
