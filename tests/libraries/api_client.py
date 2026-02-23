import time
import hmac
import hashlib
import requests
from urllib.parse import urlencode


def build_signed_payload(method, params, timestamp, recv_window):
    payload = {"method": method, "timestamp": int(timestamp), "recvWindow": int(recv_window)}
    if params:
        payload.update(params)
    query = urlencode(payload)
    return payload, query


def generate_signature(secret, query):
    message = query.encode("utf-8")
    key = secret.encode("utf-8")
    return hmac.new(key, message, hashlib.sha512).hexdigest()


def call_private_method(base_url, api_key, api_secret, method, params=None, timestamp=None, recv_window=5000):
    if timestamp is None:
        timestamp = int(time.time() * 1000)
    payload, query = build_signed_payload(method, params or {}, timestamp, recv_window)
    signature = generate_signature(api_secret, query)
    headers = {"Key": api_key, "Sign": signature}
    response = requests.post(base_url, data=payload, headers=headers, timeout=30)
    return response.json()
