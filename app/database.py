import os
import time
import logging
from dotenv import load_dotenv
import psycopg
from psycopg.rows import dict_row

load_dotenv()

logger = logging.getLogger(__name__)


def get_db_connection(retries: int = 5, delay: float = 2.0):
    """
    Open and return a psycopg connection with dict_row factory.

    Retries up to `retries` times with `delay` seconds between attempts.
    This handles the startup race condition where the Flask container is ready
    before Postgres has finished initialising — even with a healthcheck in
    docker-compose, the first few application-level queries can still fail.
    """
    last_error = None

    for attempt in range(1, retries + 1):
        try:
            return psycopg.connect(
                host=os.getenv("DB_HOST", "localhost"),
                port=os.getenv("DB_PORT", "5432"),
                dbname=os.getenv("DB_NAME"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                row_factory=dict_row,
            )
        except psycopg.OperationalError as e:
            last_error = e
            logger.warning(
                "Database connection attempt %d/%d failed: %s",
                attempt, retries, e
            )
            if attempt < retries:
                time.sleep(delay)

    raise RuntimeError(
        f"Could not connect to the database after {retries} attempts."
    ) from last_error
