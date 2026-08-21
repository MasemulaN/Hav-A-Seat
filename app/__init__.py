import os
from flask import Flask
from dotenv import load_dotenv

load_dotenv()


def create_app():
    app = Flask(__name__)

    # SECRET_KEY is required for Flask to sign session cookies and flash messages.
    # Falls back to a hard-coded dev value so the app starts locally without .env,
    # but a real secret must be set in production via the .env file.
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "change-me-in-production")

    from app.routes import main
    app.register_blueprint(main)

    from app.admin import admin
    app.register_blueprint(admin)

    return app
