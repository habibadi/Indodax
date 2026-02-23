import os
import mysql.connector
from env_loader import load_environment_config


def get_mysql_connection(env: str):
    cfg = load_environment_config(env)

    db_host = cfg.get("db_host", "127.0.0.1")
    db_name = cfg.get("db_name", "db_indodax")

    # user/password jangan di config, ambil dari environment variable
    env_upper = env.upper()
    db_user = os.environ.get(f"DB_USER_{env_upper}", "root")
    db_password = os.environ.get(f"DB_PASSWORD_{env_upper}", "")

    conn = mysql.connector.connect(
        host=db_host,
        user=db_user,
        password=db_password,
        database=db_name,
    )
    return conn
