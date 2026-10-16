"""Configuration and filesystem boundaries. No credentials belong in app.yaml."""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import yaml

SLUG = re.compile(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$')
IDENTIFIER = re.compile(r'^[a-zA-Z][a-zA-Z0-9]*(?:\.[a-zA-Z][a-zA-Z0-9]*){2,}$')
VERSION = re.compile(r'^\d+\.\d+\.\d+$')
TEST_PUBLISHER = 'ca-app-pub-3940256099942544'
TEST_APP_IDS = {'android': TEST_PUBLISHER+'~3347511713', 'ios': TEST_PUBLISHER+'~1458002511'}
TEST_UNITS = {
 'android': {'banner':'6300978111','interstitial':'1033173712','rewarded':'5224354917'},
 'ios': {'banner':'2934735716','interstitial':'4411468910','rewarded':'1712485313'},
}
class FactoryError(Exception):
    """Safe, user-facing failure; never include credential values."""

def read_yaml(path: Path) -> dict:
    try:
        data = yaml.safe_load(path.read_text())
    except (OSError, yaml.YAMLError) as e:
        raise FactoryError(f'Cannot read YAML: {path.name} ({type(e).__name__})') from None
    if not isinstance(data, dict):
        raise FactoryError(f'{path.name} must contain a mapping')
    return data

def write_yaml(path: Path, data: dict):
    atomic_write(path, yaml.safe_dump(data, sort_keys=False, allow_unicode=True))

def atomic_write(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name+'.factory-tmp')
    tmp.write_text(text)
    tmp.replace(path)

def app_path(root: Path, slug: str) -> Path:
    if not SLUG.fullmatch(slug):
        raise FactoryError('App slug must be lowercase snake_case; paths are not accepted')
    path = root/'apps'/slug
    if path.resolve().parent != (root/'apps').resolve():
        raise FactoryError('App path escapes apps directory')
    return path

def load_app(root: Path, slug: str) -> tuple[Path, dict]:
    path = app_path(root, slug)
    data = read_yaml(path/'app.yaml')
    if data.get('app', {}).get('slug') != slug:
        raise FactoryError('app.slug must match its directory')
    return path, data

def run(args: list[str], cwd: Path):
    print('+ '+ ' '.join(args), flush=True)
    try:
        subprocess.run(args, cwd=cwd, check=True)
    except FileNotFoundError:
        raise FactoryError(f'Required tool missing: {args[0]}') from None
    except subprocess.CalledProcessError as e:
        raise FactoryError(f'{args[0]} failed (exit {e.returncode})') from None

def registry(root: Path) -> dict:
    data = read_yaml(root/'factory.yaml')
    if data.get('schema_version') != 1 or not isinstance(data.get('apps'), list):
        raise FactoryError('factory.yaml schema_version must be 1 with an apps list')
    return data

def register(root: Path, slug: str):
    data=registry(root)
    if slug not in data['apps']:
        data['apps'].append(slug)
        data['apps'].sort()
        write_yaml(root/'factory.yaml', data)

def config_digest(data: dict) -> str:
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()

def public_defines(data: dict, flavor: str, platform: str = '') -> dict:
    f=data['flavors'][flavor]
    units=data['monetization']['units']
    # Test-mode is forced for dev and all automated tests. Native app IDs follow flavor too.
    defines={'FLAVOR':flavor,'APP_NAME':data['app']['name'], 'API_URL':f['api_url'],
      'ADMOB_ENABLED':str(data['monetization']['admob']).lower(),
      'FEATURE_FLAGS':json.dumps(data.get('feature_flags',{}),sort_keys=True)}
    for p in ('android','ios'):
        for kind in ('banner','interstitial','rewarded'):
            defines[f'ADMOB_{p.upper()}_{kind.upper()}']= (
                TEST_PUBLISHER+'/'+TEST_UNITS[p][kind] if flavor=='dev' else units[p][kind])
    return defines

def require_env(names: list[str]):
    missing=[n for n in names if not os.environ.get(n)]
    if missing:
        raise FactoryError('Missing secure environment variables: '+', '.join(missing))
