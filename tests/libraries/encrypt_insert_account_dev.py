import os
import binascii
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

API_KEY = ""
API_SECRET = ""


def get_master_key():
    hex_key = os.environ.get("INDODAX_TEST_MASTER_KEY_DEV")
    if not hex_key:
        raise RuntimeError("INDODAX_TEST_MASTER_KEY_DEV is not set")
    key_bytes = binascii.unhexlify(hex_key.strip())
    if len(key_bytes) not in (16, 24, 32):
        raise RuntimeError(f"Master key length must be 16/24/32 bytes, got {len(key_bytes)}")
    return key_bytes


def encrypt_value(aes_key: bytes, plaintext: str) -> str:
    aesgcm = AESGCM(aes_key)
    nonce = os.urandom(12)  # 96-bit nonce untuk GCM
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
    blob = nonce + ciphertext  # simpan nonce + ciphertext+tag
    return base64.b64encode(blob).decode("ascii")


def main():
    env = "dev"
    label = "acc_testing_01"
    description = "Account dev untuk trading flow"

    master_key = get_master_key()

    api_key_enc_b64 = encrypt_value(master_key, API_KEY)
    api_secret_enc_b64 = encrypt_value(master_key, API_SECRET)

    sql = (
        "INSERT INTO test_accounts (env, label, api_key_enc, api_secret_enc, description) "
        f"VALUES ('{env}', '{label}', "
        f"FROM_BASE64('{api_key_enc_b64}'), "
        f"FROM_BASE64('{api_secret_enc_b64}'), "
        f"'{description}');"
    )

    print(sql)


if __name__ == "__main__":
    main()