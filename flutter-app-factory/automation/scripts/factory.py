#!/usr/bin/env python3
"""App Factory CLI. Use --help; external writes always require explicit flags."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'automation'))
from model import FactoryError, atomic_write, load_app, read_yaml, registry, require_env, write_yaml
import native
import operations
from integrations import configure
from validators import release as checks
from workflows import ci
import orchestrator

def parser():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=ROOT,help='Factory root containing factory.yaml')
    commands=p.add_subparsers(dest='command',required=True)
    commands.add_parser('list',help='List registered apps')
    init=commands.add_parser('init',help='Export the starter to a new monorepo directory');init.add_argument('--dir',type=Path,required=True)
    create=commands.add_parser('create',help='Create an app using the shared house template');create.add_argument('--name',required=True);create.add_argument('--slug');create.add_argument('--org',default='com.example')
    for name in ('flavors','configure','validate','test','build','assets','metadata','ci-prepare','ci-trigger','release'):
        cmd=commands.add_parser(name);cmd.add_argument('app')
        if name=='ci-prepare':cmd.add_argument('--platform',choices=('android','ios'))
        if name in ('build','ci-prepare','ci-trigger'):cmd.add_argument('--flavor',choices=('dev','prod'),default='dev')
        if name in ('build','ci-trigger'):cmd.add_argument('--platform',choices=('android','ios'),required=True)
        if name=='validate':cmd.add_argument('--release',action='store_true');cmd.add_argument('--platform',choices=('android','ios'))
        if name in ('build','assets','ci-trigger','release'):cmd.add_argument('--execute',action='store_true',help='Execute the described action; remote builds require explicit user authorization')
        if name=='configure':cmd.add_argument('--admob',action='store_true');cmd.add_argument('--firebase',action='store_true')
        if name=='release':
            cmd.add_argument('--version',required=True);cmd.add_argument('--build-number',type=int,required=True)
            cmd.add_argument('--targets',default='play-internal,testflight');cmd.add_argument('--authorize-testing',action='store_true')
    stat=commands.add_parser('status');stat.add_argument('--provider',choices=('codemagic','release'),required=True);stat.add_argument('--id',required=True)
    commands.add_parser('ci-generate',help='Generate explicit per-app workflows')
    return p

def execute(args):
    root=args.root.resolve();command=args.command
    if command=='init':return operations.initialize(root,args.dir)
    if command=='list':return registry(root)
    if command=='create':return operations.create(root,args.name,args.slug,args.org)
    if command=='ci-generate':return {'status':'generated','path':str(ci.generate(root))}
    if command=='status':
        if args.provider=='release':return orchestrator.status(root,args.id)
        require_env(['CODEMAGIC_API_TOKEN']);return ci.status(os.environ['CODEMAGIC_API_TOKEN'],args.id)
    app,data=load_app(root,args.app)
    if command=='flavors':native.sync(root,app,data);return {'status':'flavors_configured','app':args.app,'native_builds_verified':False}
    if command=='configure':
        # Opt-ins only; disabling requires a reviewed edit to app.yaml.
        if args.admob:data['monetization']['admob']=True
        if args.firebase:data['firebase']['enabled']=True
        configure(app,data);write_yaml(app/'app.yaml',data);native.sync(root,app,data)
        operations.resolve(root,app)
        return {'status':'local_adapters_configured','cloud_resources_created':False,'manual_requirements':['Review consent/privacy placements','Configure Firebase client apps per docs/firebase.md if enabled']}
    if command=='validate':return checks.validate(root,app,data,args.release,args.platform)
    if command=='test':return operations.test(root,app)
    if command=='build':return operations.build(root,app,data,args.flavor,args.platform,args.execute)
    if command=='assets':return operations.assets(root,app,data,args.execute)
    if command=='metadata':
        errors=checks.metadata(app)
        if errors:raise FactoryError('; '.join(errors))
        # Export reviewed text into the official direct publisher adapters' schemas.
        localized={};apple_localized={}
        for path in sorted((app/'store').glob('*.yaml')):
            meta=read_yaml(path);a=meta['android'];i=meta['ios'];locale=meta.get('locale',path.stem)
            localized[locale]={'title':a['title'],'shortDescription':a['short_description'],'fullDescription':a['full_description']}
            apple_localized[locale]={'keywords':i['keywords'],'description':i['description'],'promotionalText':i['promotional_text'],'whatsNew':i['release_notes'],'supportUrl':i['support_url'],**({'marketingUrl':i['marketing_url']} if i['marketing_url'] else {})}
        out=root/'.factory/metadata'/args.app
        atomic_write(out/'play.json',json.dumps(localized,indent=2,ensure_ascii=False)+'\n')
        atomic_write(out/'apple.json',json.dumps(apple_localized,indent=2,ensure_ascii=False)+'\n')
        return {'status':'metadata_limits_validated','exported_to':str(out),'keyword_metrics_invented':False,'remote_metadata_updated':False}
    if command=='ci-prepare':
        native.sync(root,app,data,ios=False)
        native.prepare_firebase(app,data,args.flavor,platform=args.platform)
        return {'status':'ci_public_config_prepared','flavor':args.flavor}
    if command=='ci-trigger':
        workflow=ci.workflow_id(args.app,args.flavor,args.platform)
        if not args.execute:return {'status':'remote_build_plan','workflow_id':workflow,'paid_build_started':False}
        report=checks.validate(root,app,data,args.flavor=='prod',args.platform)
        if not report['ready']:raise FactoryError('Build blocked: '+'; '.join(report['errors']))
        require_env(['CODEMAGIC_API_TOKEN']);orchestrator.committed_revision(root,data['deployment']['branch'])
        return ci.trigger(os.environ['CODEMAGIC_API_TOKEN'],data['deployment']['codemagic_app_id'],workflow,data['deployment']['branch'])
    if command=='release':return orchestrator.prepare(root,app,data,args.version,args.build_number,args.targets.split(','),args.execute,args.authorize_testing)
    raise FactoryError('Unknown command')

def main(argv=None):
    args=parser().parse_args(argv)
    try:
        result=execute(args)
        print(json.dumps(result,indent=2,ensure_ascii=False))
        return 1 if result.get('ready') is False or result.get('status')=='blocked' else 0
    except (FactoryError,ValueError,KeyError,TypeError,OSError,RuntimeError) as error:
        # Do not echo provider payloads, subprocess output, or credential values.
        message=str(error) if isinstance(error,(FactoryError,ValueError,RuntimeError)) else 'Invalid configuration or filesystem operation ('+type(error).__name__+'); inspect command help and app.yaml'
        print(json.dumps({'status':'error','error':message}),file=sys.stderr)
        return 1
if __name__=='__main__':raise SystemExit(main())
