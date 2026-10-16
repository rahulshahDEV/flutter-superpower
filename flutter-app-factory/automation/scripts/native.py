"""Repeatable native edits for factory-created applications only."""
from __future__ import annotations
import base64
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import xml.etree.ElementTree as ET
from model import FactoryError, TEST_APP_IDS, atomic_write, public_defines

ANDROID_NS='http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID_NS)

def sync(root: Path, app: Path, data: dict, *, ios: bool = True):
    if not (app/'.factory-owned').is_file():
        raise FactoryError('Native edits require .factory-owned; adopt existing apps through a reviewed migration')
    if data['platforms']['android']:
        gradle=app/'android/app/build.gradle.kts'
        text=gradle.read_text()
        start='    // FACTORY START\n'; end='    // FACTORY END\n'
        body='    buildFeatures { resValues = true }\n    flavorDimensions += "environment"\n    productFlavors {\n'
        for flavor in ('dev','prod'):
            f=data['flavors'][flavor]
            admob=TEST_APP_IDS['android'] if flavor=='dev' or not data['monetization']['admob'] else data['monetization']['android_app_id']
            body+=f'''        create("{flavor}") {{
            dimension = "environment"
            applicationId = {json.dumps(f['android_application_id'])}
            resValue("string", "app_name", {json.dumps(data['app']['name']+(' Dev' if flavor=='dev' else ''))})
            manifestPlaceholders["admobAppId"] = {json.dumps(admob)}
        }}
'''
        body+='    }\n'
        body+='''    signingConfigs {
        create("factoryRelease") {
            val keystorePath = System.getenv("CM_KEYSTORE_PATH")
            if (!keystorePath.isNullOrEmpty()) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            }
        }
    }
'''
        block=start+body+end
        if start in text:
            text=re.sub(re.escape(start)+'.*?'+re.escape(end), lambda _:block, text, flags=re.S)
        elif 'android {' in text:
            text=text.replace('android {','android {\n'+block,1)
        else:
            raise FactoryError('Unsupported Android Gradle layout; no files changed')
        text=re.sub(r'signingConfig = signingConfigs.getByName\("(?:debug|factoryRelease)"\)',
          'signingConfig = signingConfigs.getByName("factoryRelease")',text)
        atomic_write(gradle,text)
        manifest=app/'android/app/src/main/AndroidManifest.xml'
        tree=ET.parse(manifest); top=tree.getroot(); application=top.find('application')
        if application is None: raise FactoryError('Missing Android application element')
        application.set('{'+ANDROID_NS+'}label','@string/app_name')
        # Flutter's template only grants network access in debug; release networking needs it.
        permissions=set(data['privacy'].get('android_permissions',[]))|{'android.permission.INTERNET'}
        existing={n.get('{'+ANDROID_NS+'}name') for n in top.findall('uses-permission')}
        for permission in sorted(permissions-existing):
            ET.SubElement(top,'uses-permission',{'{'+ANDROID_NS+'}name':permission})
        for node in list(application.findall('meta-data')):
            if node.get('{'+ANDROID_NS+'}name')=='com.google.android.gms.ads.APPLICATION_ID': application.remove(node)
        if data['monetization']['admob']:
            ET.SubElement(application,'meta-data',{'{'+ANDROID_NS+'}name':'com.google.android.gms.ads.APPLICATION_ID','{'+ANDROID_NS+'}value':'${admobAppId}'})
        atomic_write(manifest,ET.tostring(top,encoding='unicode'))
    if data['platforms']['ios'] and ios:
        payload=app/'.factory-native.json'
        atomic_write(payload,json.dumps(data))
        try:
            result=subprocess.run(['ruby',str(root/'automation/scripts/ios_flavors.rb'),str(app),str(payload)],capture_output=True,text=True)
            if result.returncode:
                raise FactoryError('iOS scheme update failed; install Ruby xcodeproj gem and inspect project compatibility')
        except FileNotFoundError:
            raise FactoryError('Ruby and xcodeproj gem required to configure native iOS schemes') from None
        finally:
            payload.unlink(missing_ok=True)
        plist=app/'ios/Runner/Info.plist'
        obj=plistlib.loads(plist.read_bytes())
        obj['CFBundleDisplayName']='$(APP_DISPLAY_NAME)'
        if data['monetization']['admob']: obj['GADApplicationIdentifier']='$(ADMOB_APP_ID)'
        else: obj.pop('GADApplicationIdentifier',None)
        obj.update(data['privacy'].get('ios_usage_descriptions',{}))
        plist.write_bytes(plistlib.dumps(obj,sort_keys=False))
        podfile=app/'ios/Podfile'
        if podfile.exists():
            s=podfile.read_text()
            for flavor in ('dev','prod'):
                for mode in ('Debug','Profile','Release'):
                    line=f"  '{mode}-{flavor}' => :{'debug' if mode=='Debug' else 'release'},"
                    if line not in s: s=s.replace("  'Debug' => :debug,", "  'Debug' => :debug,\n"+line,1)
            atomic_write(podfile,s)
    for flavor in ('dev','prod'):
        atomic_write(app/f'config/{flavor}.json',json.dumps(public_defines(data,flavor),indent=2)+'\n')
        atomic_write(app/f'.env.{flavor}','BASE_URL='+data['flavors'][flavor]['api_url']+'\n')

def prepare_firebase(app: Path, data: dict, flavor: str, platform: str | None = None, validate_only: bool = False):
    if not data['firebase']['enabled']: return
    # FlutterFire produces client configuration; this is not an Admin SDK credential.
    folder=app/'config/firebase'/flavor
    if not validate_only: folder.mkdir(parents=True,exist_ok=True)
    for env,name in [('FIREBASE_ANDROID_CONFIG_BASE64','google-services.json'),('FIREBASE_IOS_CONFIG_BASE64','GoogleService-Info.plist')]:
        if os.environ.get(env) and not validate_only:
            try: payload=base64.b64decode(os.environ[env],validate=True)
            except ValueError: raise FactoryError(f'{env} is invalid base64') from None
            dest=folder/name;dest.write_bytes(payload)
            dest.chmod(0o600)
    android=folder/'google-services.json'; apple=folder/'GoogleService-Info.plist'
    f=data['flavors'][flavor]
    if data['platforms']['android'] and platform in (None,'android'):
        if not android.is_file(): raise FactoryError(f'Missing Firebase Android client config for {flavor}')
        obj=json.loads(android.read_text())
        packages=[c.get('client_info',{}).get('android_client_info',{}).get('package_name') for c in obj.get('client',[])]
        if f['android_application_id'] not in packages or obj.get('project_info',{}).get('project_id')!=f['firebase_project']:
            raise FactoryError('Firebase Android package/project does not match selected flavor')
        if not validate_only:
            dest=app/f'android/app/src/{flavor}/google-services.json';dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(android.read_bytes())
    if data['platforms']['ios'] and platform in (None,'ios'):
        if not apple.is_file(): raise FactoryError(f'Missing Firebase iOS client config for {flavor}')
        obj=plistlib.loads(apple.read_bytes())
        if obj.get('BUNDLE_ID')!=f['ios_bundle_id'] or obj.get('PROJECT_ID')!=f['firebase_project']:
            raise FactoryError('Firebase iOS bundle/project does not match selected flavor')
        if not validate_only: (app/'ios/Runner/GoogleService-Info.plist').write_bytes(apple.read_bytes())
