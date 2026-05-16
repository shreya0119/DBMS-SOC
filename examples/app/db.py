# app/db.py
# Database connection helper using mysql-connector-python

import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv
from contextlib import contextmanager

load_dotenv()  # loads .env file from project root

DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "user":     os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "admin123"),
    "database": os.getenv("DB_NAME", "soc_db"),
    "autocommit": False,  # we control commits manually for transactions
}


def get_connection():
    """Return a new MySQL connection. Raises RuntimeError on failure."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        raise RuntimeError(f"Database connection failed: {e}") from e


@contextmanager
def get_db():
    """
    Context manager for database access.
    Usage:
        with get_db() as (conn, cursor):
            cursor.execute(...)
            conn.commit()
    Automatically closes connection on exit.
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)  # returns rows as dicts
    try:
        yield conn, cursor
    except Error as e:
        conn.rollback()
        raise RuntimeError(f"Database error: {e}") from e
    finally:
        cursor.close()
        conn.close()