#!/bin/bash
set -e

echo "✅ Starting entrypoint script..."

# Create default requirements.txt if not present
if [ ! -f /app/requirements.txt ]; then
  echo "⚠️ No requirements.txt found, creating an empty one..."
  touch /app/requirements.txt
fi

# Create /tmp/python dir if missing (should already exist)
mkdir -p /tmp/python/lib/python3.12/site-packages/

echo "⚙️ Installing Python requirements..."
/opt/bin/pip3.12 install -r /app/requirements.txt -t /tmp/python/lib/python3.12/site-packages/

echo "🔎 Finding compiled rust extensions..."
find /tmp/python -name "_rust.abi3.so" || echo "No rust extensions found."

echo "📦 Creating zip file for Lambda layer..."
cd /tmp
zip -r9q /app/ftpclient-python-requirements312.zip python -x '*.dist-info*' -x '*.egg-info*'

echo "✅ Done! Zip file created:"
du -sh /app/ftpclient-python-requirements312.zip
