"""Short-lived App Store Connect team-key JWTs; key material stays in memory."""
import base64
import json
from pathlib import Path
import time

from .common import PublishingError, require_env


def token_provider():
    key_id = require_env("ASC_KEY_ID")
    issuer = require_env("ASC_ISSUER_ID")
    key_path = Path(require_env("ASC_PRIVATE_KEY_PATH"))
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import ec, utils
    except ImportError:
        raise PublishingError("Install automation/requirements.txt for cryptography") from None
    try:
        private_key = serialization.load_pem_private_key(key_path.read_bytes(), password=None)
        if not isinstance(private_key, ec.EllipticCurvePrivateKey) or private_key.curve.name != "secp256r1":
            raise ValueError("Expected P-256 key")
    except (OSError, ValueError, TypeError):
        raise PublishingError("ASC_PRIVATE_KEY_PATH must point to a readable ES256 .p8 team key") from None
    cache = {"expires": 0, "token": ""}

    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value, separators=(",", ":")).encode()).rstrip(b"=")

    def token():
        now = int(time.time())
        if now >= cache["expires"] - 30:
            header = encode({"alg": "ES256", "kid": key_id, "typ": "JWT"})
            payload = encode({"iss": issuer, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"})
            message = header + b"." + payload
            signature = private_key.sign(message, ec.ECDSA(hashes.SHA256()))
            r, s = utils.decode_dss_signature(signature)
            encoded = base64.urlsafe_b64encode(r.to_bytes(32, "big") + s.to_bytes(32, "big")).rstrip(b"=")
            cache.update(expires=now + 600, token=(message + b"." + encoded).decode())
        return cache["token"]

    return token
