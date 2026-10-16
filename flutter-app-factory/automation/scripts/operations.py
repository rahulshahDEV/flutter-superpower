"""Local factory operations. Commands use argument arrays, never shell interpolation."""
from __future__ import annotations
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import yaml
from model import (FactoryError, SLUG, IDENTIFIER, app_path, atomic_write, load_app, public_defines,
                   read_yaml, register, registry, require_env, run, write_yaml)
import native
from integrations import configure

def replace_values(value, substitutions):
    if isinstance(value,dict):return {k:replace_values(v,substitutions) for k,v in value.items()}
    if isinstance(value,list):return [replace_values(v,substitutions) for v in value]
    if isinstance(value,str):
        for key,text in substitutions.items():value=value.replace(key,text)
    return value

def initialize(root: Path, dest: Path):
    root=root.resolve()
    dest=dest.resolve()
    if dest.exists():raise FactoryError('Destination exists; choose a new directory')
    if dest.is_relative_to(root):raise FactoryError('Export outside the starter directory')
    manifest=root/'automation/export-manifest.txt'
    if not manifest.is_file():raise FactoryError('Missing maintained export manifest; refuse unbounded directory copying')
    entries=manifest.read_text().splitlines()
    sources=[]
    forbidden_exact={'.env', '.env.production', 'key.properties', 'local.properties', 'service-account.json'}
    forbidden_prefix=('service-account', 'service_account', 'google-services', 'GoogleService-Info')
    for relative in entries:
        if not relative or relative.startswith('#'):continue
        source=root/relative
        if not source.resolve().is_relative_to(root.resolve()) or any(part in forbidden_exact or part.startswith(forbidden_prefix) for part in source.parts) or source.suffix.lower() in ('.jks','.keystore','.p8','.p12','.mobileprovision'):
            raise FactoryError('Export manifest contains unsafe path')
        if not source.is_file() or any(p.is_symlink() for p in [source,*source.parents] if p.is_relative_to(root)):
            raise FactoryError('Export manifest contains missing file or symlink')
        sources.append((source,relative))
    dest.mkdir(parents=True)
    for source,relative in sources:
        target=dest/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    # Runtime caches and user credentials never enter the maintained export manifest.
    return {'status':'factory_exported','directory':str(dest),'next':'Install automation/requirements.txt, then create an app'}

def create(root: Path, name: str, slug: str | None, org: str):
    slug=slug or re.sub(r'[^a-z0-9]+','_',name.lower()).strip('_')
    dest=app_path(root,slug)
    if not IDENTIFIER.fullmatch(org+'.app'):raise FactoryError('Organization must be a reverse-domain identifier')
    if not name.strip() or any(ord(c)<32 for c in name):raise FactoryError('App name must be nonempty single-line text')
    if dest.exists():
        _,config=load_app(root,slug)
        if config['app']['name']==name and config['android']['application_id']==org+'.'+slug.replace('_',''):
            return {'status':'already_exists','app':slug,'note':'Existing files preserved; validate before building'}
        raise FactoryError('App directory already exists; important configuration was preserved')
    identity=org+'.'+slug.replace('_','')
    for other in registry(root)['apps']:
        _,data=load_app(root,other)
        if identity in [f[k] for f in data['flavors'].values() for k in ('android_application_id','ios_bundle_id')]:raise FactoryError('Application identifier collides with '+other)
    staging=root/'.factory/staging';staging.mkdir(parents=True,exist_ok=True)
    tmp=Path(tempfile.mkdtemp(prefix=slug+'-',dir=staging))/slug
    run(['flutter','create','--no-pub','--org',org,'--project-name',slug,'--platforms','android,ios',str(tmp)],root)
    substitutions={'__APP_NAME__':slug,'__APP_CLASS__':''.join(p.title() for p in slug.split('_')),'__APP_TITLE__':name,'__ORG__':org,'__APP_ID__':slug.replace('_','')}
    for source in (root/'templates/flutter_app').rglob('*'):
        if not source.is_file() or any(x in source.parts for x in ('.dart_tool','build')) or source.name in ('pubspec.lock','.flutter-plugins-dependencies'):continue
        target=tmp/source.relative_to(root/'templates/flutter_app');target.parent.mkdir(parents=True,exist_ok=True)
        if source.suffix in ('.yaml','.yml'):
            target.write_text(yaml.safe_dump(replace_values(yaml.safe_load(source.read_text()),substitutions),sort_keys=False,allow_unicode=True))
        else:
            subs=dict(substitutions)
            if source.suffix=='.dart':subs['__APP_TITLE__']=name.replace('\\','\\\\').replace("'","\\'").replace('$','\\$')
            target.write_text(replace_values(source.read_text(),subs))
    (tmp/'assets/images').mkdir(parents=True,exist_ok=True)
    (tmp/'assets/branding').mkdir(parents=True,exist_ok=True)
    config=replace_values(read_yaml(root/'templates/app_config/app.yaml'),substitutions)
    write_yaml(tmp/'app.yaml',config)
    metadata=read_yaml(root/'templates/store_metadata/en-US.yaml')
    metadata['android']['title']=name;metadata['ios']['name']=name
    write_yaml(tmp/'store/en-US.yaml',metadata)
    (tmp/'.factory-owned').write_text('Factory native configuration schema 1\n')
    # flutter create's default counter test is replaced by the house smoke tests.
    native.sync(root,tmp,config)
    dest.parent.mkdir(parents=True,exist_ok=True)
    tmp.rename(dest)
    register(root,slug)
    from workflows.ci import generate
    generate(root)
    resolve(root,dest)
    return {'status':'created','app':slug,'configuration':f'apps/{slug}/app.yaml','release_ready':False}

def resolve(root: Path, app: Path):
    run(['flutter','pub','get'],app)
    generate_code(app)
    run(['dart','format','lib','test'],app)

def generate_code(app: Path):
    if shutil.which('fdev'):run(['fdev','gen','--','--force-jit'],app)
    else:run(['dart','run','build_runner','build','--delete-conflicting-outputs','--force-jit'],app)

def test(root: Path, app: Path):
    for path in [*sorted((root/'packages').iterdir()),app]:
        if not (path/'pubspec.yaml').is_file():continue
        run(['flutter','pub','get'],path)
        run(['dart','format','--output=none','--set-exit-if-changed','lib',*(['test'] if (path/'test').is_dir() else [])],path)
        if path==app:generate_code(path)
        run(['flutter','analyze'],path)
        if (path/'test').is_dir():run(['flutter','test','--dart-define=AUTOMATED_TEST=true'],path)
    return {'status':'local_checks_passed','app':app.name}

def build(root: Path, app: Path, data: dict, flavor: str, platform: str, execute: bool):
    if not data['platforms'][platform]:raise FactoryError('Requested platform is disabled')
    flags=['--flavor',flavor,'--target',f'lib/main_{flavor}.dart','--dart-define-from-file',f'config/{flavor}.json', '--build-name',data['app']['version'],'--build-number',str(data['app']['build_number'])]
    command=['flutter','build',*(['appbundle','--release'] if platform=='android' and flavor=='prod' else ['apk','--debug'] if platform=='android' else ['ipa','--release'] if flavor=='prod' else ['ios','--simulator','--debug']),*flags]
    if not execute:return {'status':'build_plan','app':app.name,'command':command,'uploaded':False}
    native.sync(root,app,data)
    native.prepare_firebase(app,data,flavor,platform=platform)
    from validators.release import validate
    report=validate(root,app,data,release=flavor=='prod',platform=platform)
    if not report['ready']:raise FactoryError('Build blocked: '+'; '.join(report['errors']))
    if flavor=='prod' and platform=='android':require_env(['CM_KEYSTORE_PATH','CM_KEYSTORE_PASSWORD','CM_KEY_ALIAS','CM_KEY_PASSWORD'])
    resolve(root,app)
    run(command,app)
    return {'status':'local_build_completed','app':app.name,'platform':platform,'uploaded':False,'note':'Verify artifact before distribution'}

def assets(root: Path,app: Path,data:dict,execute:bool):
    from validators.release import assets as check_assets
    errors=check_assets(app,data)
    if errors:raise FactoryError('; '.join(errors))
    configs={
      'flutter_launcher_icons.yaml':{'flutter_launcher_icons':{'android':True,'ios':True,'image_path':data['assets']['icon'],'remove_alpha_ios':True}},
      'flutter_native_splash.yaml':{'flutter_native_splash':{'color':'#FFFFFF','color_dark':'#111111','image':data['assets']['splash'],'android':True,'ios':True,'android_12':{'color':'#FFFFFF','image':data['assets']['splash']}}},
    }
    for name,content in configs.items():
        path=app/name
        if path.exists() and read_yaml(path)!=content:raise FactoryError('Existing '+name+' differs; review before changing')
        write_yaml(path,content)
    if execute:
        if not (app/data['assets']['icon']).is_file() or not (app/data['assets']['splash']).is_file():raise FactoryError('Supply actual icon and splash images before generating assets')
        spec=read_yaml(app/'pubspec.yaml');spec['dev_dependencies'].update({'flutter_launcher_icons':'^0.14.4','flutter_native_splash':'^2.4.6'});write_yaml(app/'pubspec.yaml',spec)
        run(['flutter','pub','get'],app)
        run(['fdev','icons'] if shutil.which('fdev') else ['dart','run','flutter_launcher_icons'],app)
        run(['fdev','splash'] if shutil.which('fdev') else ['dart','run','flutter_native_splash:create'],app)
    return {'status':'assets_generated' if execute else 'asset_configuration_prepared','graphics_generated':False}
