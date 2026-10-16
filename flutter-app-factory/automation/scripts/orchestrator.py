"""Reviewable release plans and resumable, explicitly authorized testing builds."""
from __future__ import annotations
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
from model import FactoryError, VERSION, atomic_write, config_digest, read_yaml, require_env, write_yaml
from validators.release import validate
import operations
from workflows import ci

TARGETS={'play-internal':'android','testflight':'ios'}

def set_version(app:Path,data:dict,version:str,build_number:int):
    if not VERSION.fullmatch(version) or build_number<1:raise FactoryError('Use version X.Y.Z and a positive build number')
    old=(tuple(map(int,data['app']['version'].split('.'))),data['app']['build_number'])
    new=(tuple(map(int,version.split('.'))),build_number)
    if new[0]<old[0] or new[1]<old[1]:raise FactoryError('Refusing to decrease version or build number')
    if new!=old and build_number<=old[1]:raise FactoryError('Changed release must increase build number for store uniqueness')
    data['app']['version']=version;data['app']['build_number']=build_number
    write_yaml(app/'app.yaml',data)
    spec=read_yaml(app/'pubspec.yaml');spec['version']=f'{version}+{build_number}';write_yaml(app/'pubspec.yaml',spec)

def committed_revision(root:Path,branch:str)->str:
    def git(*args):
        p=subprocess.run(['git',*args],cwd=root,capture_output=True,text=True)
        if p.returncode:raise FactoryError('Cannot verify committed remote revision; commit and push reviewed changes first')
        return p.stdout.strip()
    if git('status','--porcelain','--untracked-files=normal'):raise FactoryError('Commit and push the reviewed factory/config before starting remote builds')
    head=git('rev-parse','HEAD')
    # Read-only remote check prevents validating local data but building another revision.
    remote=git('ls-remote','origin',f'refs/heads/{branch}')
    if not remote or remote.split()[0]!=head:raise FactoryError('Remote build branch does not match validated HEAD; push reviewed commit first')
    return head

def prepare(root:Path,app:Path,data:dict,version:str,build_number:int,targets:list[str],execute:bool,authorize:bool):
    if not targets or len(targets)!=len(set(targets)) or any(t not in TARGETS for t in targets):raise FactoryError('Supported targets: play-internal,testflight; public production release requires separate reviewed publishing')
    if any(not data['platforms'].get(TARGETS[t]) for t in targets):raise FactoryError('Requested release target is disabled for this app')
    if execute and not authorize:raise FactoryError('Starting paid builds/testing uploads requires explicit authorization and --authorize-testing')
    set_version(app,data,version,build_number)
    operations.native.sync(root,app,data)
    ci.generate(root)
    platforms=sorted({TARGETS[t] for t in targets})
    reports=[validate(root,app,data,release=True,platform=p) for p in platforms]
    report={'ready':all(r['ready'] for r in reports),'errors':sorted({e for r in reports for e in r['errors']}),'warnings':sorted({w for r in reports for w in r['warnings']}),'not_verified':sorted({n for r in reports for n in r['not_verified']})}
    plan={'schema_version':1,'app':app.name,'version':version,'build_number':build_number,'targets':targets,
      'config_sha256':config_digest(data),'workflows':{t:ci.workflow_id(app.name,'prod',TARGETS[t],True) for t in targets},
      'validation':report,'status':'blocked' if not report['ready'] else 'prepared',
      'deployment_confirmed':False,'builds':{},'created_at':datetime.now(timezone.utc).isoformat()}
    release_id=f'{app.name}-{version}-{build_number}'
    journal=root/'.factory/releases'/f'{release_id}.json'
    if journal.exists():
        prior=json.loads(journal.read_text())
        if prior.get('config_sha256')!=plan['config_sha256'] or prior.get('targets')!=targets:raise FactoryError('Existing release plan differs; use a new build number')
        plan={**prior,'validation':report,'status':'blocked' if not report['ready'] else 'prepared'}
    atomic_write(journal,json.dumps(plan,indent=2)+'\n')
    if not report['ready']:return {'release_id':release_id,**plan}
    operations.test(root,app)
    plan['local_checks']='passed'
    if execute:
        require_env(['CODEMAGIC_API_TOKEN'])
        deployment=data['deployment'];revision=committed_revision(root,deployment['branch'])
        if 'REPLACE' in deployment['codemagic_app_id']:raise FactoryError('Configure Codemagic application ID before triggering builds')
        if plan.get('commit') and plan['commit']!=revision:raise FactoryError('Existing release targets another revision; use a new build number')
        plan['commit']=revision
        for target,workflow in plan['workflows'].items():
            previous=plan['builds'].get(target)
            if previous:
                if previous.get('phase')=='trigger_in_flight':raise FactoryError('Previous trigger outcome unknown; reconcile Codemagic dashboard before retrying')
                continue
            plan['builds'][target]={'phase':'trigger_in_flight'}
            atomic_write(journal,json.dumps(plan,indent=2)+'\n')
            receipt=ci.trigger(os.environ['CODEMAGIC_API_TOKEN'],deployment['codemagic_app_id'],workflow,deployment['branch'])
            plan['builds'][target]={'phase':'queued',**receipt}
            atomic_write(journal,json.dumps(plan,indent=2)+'\n')
        plan['status']='builds_triggered'
    atomic_write(journal,json.dumps(plan,indent=2)+'\n')
    return {'release_id':release_id,**plan}

def status(root:Path,release_id:str):
    if not re.fullmatch(r'[a-z][a-z0-9_]*-\d+\.\d+\.\d+-\d+',release_id):raise FactoryError('Invalid release ID')
    journal=root/'.factory/releases'/f'{release_id}.json'
    if not journal.is_file():raise FactoryError('Unknown local release journal')
    plan=json.loads(journal.read_text())
    if plan.get('builds'):
        require_env(['CODEMAGIC_API_TOKEN'])
        for receipt in plan['builds'].values():
            if receipt.get('build_id'):receipt['observed']=ci.status(os.environ['CODEMAGIC_API_TOKEN'],receipt['build_id'])
    # Build completion is not store availability; official store APIs supply that evidence.
    plan['deployment_confirmed']=False
    atomic_write(journal,json.dumps(plan,indent=2)+'\n')
    return plan
