conda activate global
Start-Process python -WindowStyle hidden -ArgumentList "-m", "jupyterlab", "--no-browser", "--expose-app-in-browser", "--ServerApp.port=8888", "--ServerApp.root_dir=C:/Users/ebogrer"
