"""Application Default Credentials with a stdlib google-auth transport."""
from types import SimpleNamespace
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from .common import PublishingError


def token_provider():
    try:
        import google.auth
        credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/androidpublisher"])
    except ImportError:
        raise PublishingError("Install automation/requirements.txt for google-auth") from None
    except Exception:
        raise PublishingError("Google Application Default Credentials are unavailable") from None

    def transport(url, method="GET", body=None, headers=None, timeout=120, **_kwargs):
        try:
            response = urlopen(Request(url, data=body, headers=headers or {}, method=method), timeout=timeout)
        except HTTPError as response:
            with response:
                return SimpleNamespace(status=response.code, data=response.read(), headers=response.headers)
        with response:
            return SimpleNamespace(status=response.status, data=response.read(), headers=response.headers)

    def token():
        if not credentials.valid:
            try:
                credentials.refresh(transport)
            except Exception:
                raise PublishingError("Google credential refresh failed; verify credential scope and access") from None
        return credentials.token

    return token
