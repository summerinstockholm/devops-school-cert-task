
from flask import Flask
import os

APPVERSION = os.getenv('APPVERSION')

app = Flask(__name__)


@app.route('/')
def hello():
    return f'<h1>Hello, World!</h1>\nVersion {APPVERSION}'

