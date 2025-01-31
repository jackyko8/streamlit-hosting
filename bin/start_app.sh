#!/bin/bash

port=${1:-8501}
streamlit run src/app/app.py --server.port $port &
echo "App started on port $port"
