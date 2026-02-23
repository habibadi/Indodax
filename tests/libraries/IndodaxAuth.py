import hmac
import hashlib
import time
import urllib.parse

class IndodaxAuth:
    def generate_indodax_signature(self, secret_key, payload):
        # Indodax membutuhkan payload dalam format query string untuk signature
        query_string = urllib.parse.urlencode(payload)
        signature = hmac.new(
            secret_key.encode('utf-8'),
            query_string.encode('utf-8'),
            hashlib.sha512
        ).hexdigest()
        return signature

    def get_nonce(self):
        return str(int(time.time() * 1000))