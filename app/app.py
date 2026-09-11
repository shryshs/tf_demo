import os

from flask import Flask

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "not-specified")


@app.route("/")
def home():
    return f"helllo this is {APP_VERSION}\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
