import os
import binascii
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from db_client import get_mysql_connection


def _get_master_key(env: str) -> bytes:
    env_upper = env.upper()
    hex_key = os.environ.get(f"INDODAX_TEST_MASTER_KEY_{env_upper}")
    if not hex_key:
        raise RuntimeError(f"INDODAX_TEST_MASTER_KEY_{env_upper} is not set")
    key_bytes = binascii.unhexlify(hex_key.strip())
    if len(key_bytes) not in (16, 24, 32):
        raise RuntimeError(f"Master key length must be 16/24/32 bytes, got {len(key_bytes)}")
    return key_bytes


def _decrypt_blob(aes_key: bytes, blob: bytes) -> str:
    # blob = nonce(12 bytes) + ciphertext+tag
    nonce = blob[:12]
    ciphertext = blob[12:]
    aesgcm = AESGCM(aes_key)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext.decode("utf-8")


def get_trading_account(env: str, label: str) -> dict:
    master_key = _get_master_key(env)
    conn = get_mysql_connection(env)
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT api_key_enc, api_secret_enc FROM test_accounts "
            "WHERE env=%s AND label=%s AND active=1",
            (env, label),
        )
        row = cur.fetchone()
        if not row:
            raise RuntimeError(f"Account '{label}' for env '{env}' not found")

        api_key = _decrypt_blob(master_key, row["api_key_enc"])
        api_secret = _decrypt_blob(master_key, row["api_secret_enc"])
        return {"api_key": api_key, "api_secret": api_secret}
    finally:
        cur.close()
        conn.close()
