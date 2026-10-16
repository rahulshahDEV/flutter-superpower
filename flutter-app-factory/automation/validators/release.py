"""Deterministic checks; store dashboards, signing validity and review remain external."""
from __future__ import annotations
import json
from pathlib import Path
import plistlib
import re
import struct
from urllib.parse import urlparse
from model import IDENTIFIER, VERSION, FactoryError, TEST_PUBLISHER, read_yaml, registry

LIMITS={'android':{'title':30,'short_description':80,'full_description':4000,'release_notes':500},
 'ios':{'name':30,'subtitle':30,'description':4000,'promotional_text':170,'release_notes':4000}}

def metadata(app: Path, release: bool = False, platforms: list[str] | None = None) -> list[str]:
    platforms=platforms or ["android","ios"]
    errors=[]
    files=list((app/'store').glob('*.yaml'))
    if not files:return ['No localized store metadata found']
    for path in files:
        data=read_yaml(path)
        for platform,limits in LIMITS.items():
            if platform not in platforms: continue
            values=data.get(platform,{})
            for key,limit in limits.items():
                value=values.get(key,'')
                if not isinstance(value,str):errors.append(f'{path.name}: {platform}.{key} must be text');continue
                if len(value)>limit:errors.append(f'{path.name}: {platform}.{key} exceeds {limit} characters')
            if release:
                required=('title','short_description','full_description','release_notes') if platform=='android' else ('name','description','release_notes','support_url')
                for key in required:
                    if not values.get(key,'').strip():errors.append(f'{path.name}: missing {platform}.{key}')
        keywords=data.get('ios',{}).get('keywords','')
        if not isinstance(keywords,str) or len(keywords.encode('utf-8'))>100:errors.append(f'{path.name}: iOS keywords exceed 100 UTF-8 bytes')
        if release:
            for p in platforms:
                shots=data.get('screenshots',{}).get(p,[])
                if not shots:errors.append(f'{path.name}: add reviewed {p} screenshots')
                for shot in shots:
                    resolved=(app/shot).resolve()
                    if not resolved.is_relative_to(app.resolve()) or not resolved.is_file(): errors.append(f'{path.name}: screenshot missing or outside app')
    return errors

def png_dimensions(path: Path) -> tuple[int,int]:
    header=path.read_bytes()[:24]
    if len(header)!=24 or header[:8]!=b'\x89PNG\r\n\x1a\n':raise FactoryError('Expected a PNG image')
    return struct.unpack('>II',header[16:24])

def assets(app: Path, data: dict, release: bool = False) -> list[str]:
    errors=[]
    icon=(app/data['assets']['icon']).resolve()
    if not icon.is_relative_to(app.resolve()):return ['Icon path escapes app']
    if icon.exists():
        if png_dimensions(icon)!=(1024,1024):errors.append('Source icon must be 1024×1024 PNG; iOS marketing icon must be opaque')
    elif release:errors.append('Missing source icon')
    if release and not data['assets'].get('reviewed'): errors.append('App icons/splash/store assets require review')
    return errors

def validate(root: Path, app: Path, data: dict, release: bool = False, platform: str | None = None) -> dict:
    errors=[];warnings=[]
    required={'app':('name','slug','version','build_number'),'android':('application_id','signing_reference'),
      'ios':('bundle_id','team_id','signing_reference'),'flavors':('dev','prod'),
      'monetization':('admob','units','android_app_id','ios_app_id'),'firebase':('enabled','analytics','crashlytics'),
      'platforms':('android','ios'),'deployment':('provider',),'privacy':('policy_url','store_declarations_reviewed'), 'assets':('icon',)}
    for section,keys in required.items():
        if not isinstance(data.get(section),dict):errors.append('Missing mapping: '+section);continue
        for key in keys:
            if key not in data[section]:errors.append(f'Missing config key {section}.{key}')
    if errors:return {'ready':False,'errors':errors,'warnings':warnings,'not_verified':['Toolchain and remote services']}
    if data.get('schema_version')!=1:errors.append('Unsupported app schema version')
    for section,keys in [('platforms',('android','ios')),('firebase',('enabled','analytics','crashlytics')),('monetization',('admob',))]:
        for key in keys:
            if type(data[section][key]) is not bool:errors.append(f'{section}.{key} must be boolean')
    if not VERSION.fullmatch(str(data['app']['version'])):errors.append('version must be X.Y.Z')
    if type(data['app']['build_number']) is not int or not 1<=data['app']['build_number']<=2100000000:errors.append('build_number must be a positive Android-compatible integer')
    if not data['app']['name'].strip():errors.append('App name cannot be blank')
    ids=[]
    for flavor in ('dev','prod'):
        f=data['flavors'][flavor]
        if not isinstance(f,dict):errors.append(f'flavors.{flavor} must be a mapping');continue
        for key in ('android_application_id','ios_bundle_id'):
            value=f.get(key,'')
            if not IDENTIFIER.fullmatch(str(value)):errors.append(f'Invalid {flavor} {key}')
            ids.append(value)
        url=f.get('api_url','')
        if url and (urlparse(url).scheme!='https' or not urlparse(url).netloc or urlparse(url).username):errors.append(f'{flavor} API URL must use HTTPS without embedded credentials')
        if flavor=='prod' and url and any(x in url.lower() for x in ('localhost','.invalid','staging.','dev.','example.com')):errors.append('Production API URL appears to be development/placeholder configuration')
    if len(ids)==4:
        if ids[0]==ids[2] or ids[1]==ids[3]:errors.append('Development and production identities must differ')
        if data['android']['application_id']!=ids[2] or data['ios']['bundle_id']!=ids[3]:errors.append('Base identifiers must match production flavor')
    registered=registry(root)['apps']
    if data['app']['slug'] not in registered:errors.append('App is not registered in factory.yaml')
    for slug in registered:
        if slug==data['app']['slug']:continue
        other=read_yaml(root/'apps'/slug/'app.yaml')
        for flavor in ('dev','prod'):
            for key in ('android_application_id','ios_bundle_id'):
                if other.get('flavors',{}).get(flavor,{}).get(key) in ids:errors.append(f'Application identity collision with {slug}')
    # Configs are public; catch common accidental private material and credentials.
    secret=re.compile(r'-----BEGIN .*PRIVATE KEY-----|"?private_key"?\s*:|AIza[A-Za-z0-9_-]{35}|(?:password|access_token|client_secret)\s*:',re.I)
    if secret.search((app/'app.yaml').read_text()):errors.append('Private material/credential key detected in public config')
    pub=read_yaml(app/'pubspec.yaml')
    if pub.get('version')!=f"{data['app']['version']}+{data['app']['build_number']}":errors.append('pubspec version differs from app.yaml')
    if pub.get('name')!=data['app']['slug']:errors.append('pubspec name differs from app slug')
    for p in ('core','ui_kit','analytics','networking','app_config'):
        if not (root/'packages'/p/'pubspec.yaml').is_file():errors.append('Shared package missing: '+p)
    platforms=[platform] if platform else [p for p in ('android','ios') if data['platforms'][p]]
    if platform and not data['platforms'][platform]:errors.append('Requested platform disabled')
    if 'android' in platforms:
        gradle=app/'android/app/build.gradle.kts'
        text=gradle.read_text() if gradle.is_file() else ''
        for flavor in ('dev','prod'):
            if f'create("{flavor}")' not in text or data['flavors'][flavor]['android_application_id'] not in text:errors.append('Android flavor/identifier not synchronized: '+flavor)
        if 'signingConfigs.getByName("debug")' in text:errors.append('Release signing must not use debug keystore')
        for permission in data['privacy'].get('android_permissions',[]):
            if permission not in (app/'android/app/src/main/AndroidManifest.xml').read_text():errors.append('Android declared permission not synchronized')
    if 'ios' in platforms:
        pbx=app/'ios/Runner.xcodeproj/project.pbxproj'
        text=pbx.read_text() if pbx.is_file() else ''
        for flavor in ('dev','prod'):
            scheme=app/f'ios/Runner.xcodeproj/xcshareddata/xcschemes/{flavor}.xcscheme'
            if not scheme.is_file() or f'Release-{flavor}' not in text:errors.append('Missing iOS scheme/configuration: '+flavor)
            if data['flavors'][flavor]['ios_bundle_id'] not in text:errors.append('iOS bundle configuration is stale')
        info=plistlib.loads((app/'ios/Runner/Info.plist').read_bytes())
        for key,value in data['privacy'].get('ios_usage_descriptions',{}).items():
            if not key.endswith('UsageDescription') or not value.strip() or info.get(key)!=value:errors.append('Missing/stale iOS permission usage description: '+key)
    if data['firebase']['enabled']:
        projects=[data['flavors'][f].get('firebase_project','') for f in ('dev','prod')]
        if not all(projects) or projects[0]==projects[1]:errors.append('Firebase requires distinct nonempty dev/prod projects')
        if release:
            from native import prepare_firebase
            try:prepare_firebase(app,data,'prod',platform=platform,validate_only=True)
            except FactoryError as exc:errors.append(str(exc))
    if release:
        for p in platforms:
            key='application_id' if p=='android' else 'bundle_id'
            if data[p][key].startswith('com.example.'):errors.append('Replace example production identity for '+p)
            if not data[p]['signing_reference'] or 'REPLACE' in data[p]['signing_reference']:errors.append('Missing signing reference: '+p)
        if 'ios' in platforms and not re.fullmatch(r'[A-Z0-9]{10}',data['ios']['team_id']):errors.append('Set valid Apple team ID')
        policy=data['privacy']['policy_url']
        if not policy.startswith('https://') or 'example.' in policy or '.invalid' in policy:errors.append('Real HTTPS privacy policy required')
        if not data['privacy']['store_declarations_reviewed']:errors.append('Privacy/permissions/store declarations require review')
        if data['monetization']['admob']:
            for p in platforms:
                app_id=data['monetization'][p+'_app_id']
                units=data['monetization']['units'].get(p,{})
                if not re.fullmatch(r'ca-app-pub-\d{16}~\d{10}',str(app_id)) or TEST_PUBLISHER in str(app_id):errors.append('Invalid/sample production AdMob app ID: '+p)
                if set(units)!={'banner','interstitial','rewarded'} or any(not re.fullmatch(r'ca-app-pub-\d{16}/\d{10}',str(v)) or TEST_PUBLISHER in str(v) for v in units.values()):errors.append('Production AdMob banner/interstitial/rewarded units required: '+p)
            if not data['privacy'].get('admob_reviewed'):errors.append('AdMob consent/placement declarations require review')
        errors+=metadata(app,True,platforms)
        errors+=assets(app,data,True)
    else:
        errors+=metadata(app)
        warnings+=assets(app,data)
        warnings.append('Development validation does not establish release readiness')
    return {'ready':not errors,'errors':sorted(set(errors)),'warnings':sorted(set(warnings)),
     'not_verified':['Signing certificate/profile validity','Store account agreements, policy questionnaires and review','Installed-device behavior and visual/privacy review','Remote artifact identities and store processing']}
