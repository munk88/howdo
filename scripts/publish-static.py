#!/usr/bin/env python3
"""Build and publish static files over the user's local SSH connection. No Docker restart."""
import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import re
import shlex
import subprocess
import tarfile
import tempfile

REMOTE = r"""
import fcntl, json, os, re, shutil, subprocess, sys, tarfile
from pathlib import Path, PurePosixPath
root, release, archive = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
if not re.fullmatch(r'[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}',release):raise ValueError('Invalid release ID')
if not root.is_absolute() or root == Path('/'):raise ValueError('Invalid site directory')
root.mkdir(parents=True,exist_ok=True)
(root/'releases').mkdir(exist_ok=True)
current=root/'current'
with (root/'.publish.lock').open('w') as lock:
 fcntl.flock(lock,fcntl.LOCK_EX)
 previous=os.readlink(current) if current.is_symlink() else None
 if current.exists() and previous is None:raise ValueError('current must be a relative symlink')
 target=root/'releases'/release
 if target.exists():raise ValueError('Release already exists')
 target.mkdir()
 switched=False
 try:
  with tarfile.open(archive,'r:gz') as tar:
   members=tar.getmembers();names=set();size=0
   for entry in members:
    path=PurePosixPath(entry.name)
    if path.is_absolute() or '..' in path.parts or not (entry.isdir() or entry.isfile()):raise ValueError('Unsafe archive')
    if entry.name in names:raise ValueError('Duplicate archive entry')
    names.add(entry.name);size+=entry.size
   if size>256*1024*1024 or len(members)>10000:raise ValueError('Archive too large')
   tar.extractall(target,filter='data')
  for name in ['index.html','404.html','rss.xml','sitemap-index.xml','search-index.json','__release.json']:
   if not (target/name).is_file():raise ValueError('Missing '+name)
  if json.loads((target/'__release.json').read_text())['release']!=release:raise ValueError('Release marker mismatch')
  link=root/('.next-'+release);link.symlink_to('releases/'+release);os.replace(link,current);switched=True
  def fetch(path):
   return subprocess.check_output(['curl','-fsS','--max-time','15','--resolve','howdo.icu:443:127.0.0.1','https://howdo.icu'+path],text=True)
  if json.loads(fetch('/__release.json'))['release']!=release:raise ValueError('Live release mismatch')
  for path in ['/','/rss.xml','/sitemap-index.xml','/search-index.json']:fetch(path)
  code=subprocess.check_output(['curl','-sS','--max-time','15','--resolve','howdo.icu:443:127.0.0.1','-o','/dev/null','-w','%{http_code}','https://howdo.icu/this-page-does-not-exist/'],text=True)
  if code!='404':raise ValueError('Expected HTTP 404')
 except Exception:
  if switched:
   if previous is not None:
    link=root/('.rollback-'+release);link.symlink_to(previous);os.replace(link,current)
   else:current.unlink()
  shutil.rmtree(target)
  raise
 finally:
  archive.unlink(missing_ok=True)
print('PUBLISHED '+release)
"""


def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--host',required=True)
 parser.add_argument('--user',default='root')
 parser.add_argument('--port',type=int,default=22)
 parser.add_argument('--key',required=True,type=Path)
 parser.add_argument('--known-hosts',type=Path)
 parser.add_argument('--site-dir',default='/opt/howdo/site')
 args=parser.parse_args()
 if not re.fullmatch(r'[a-zA-Z0-9._:-]+',args.host) or not re.fullmatch(r'[a-zA-Z0-9_-]+',args.user):parser.error('Invalid SSH host/user')
 if not 1<=args.port<=65535:parser.error('Invalid port')
 if not args.key.is_file():parser.error('SSH key file not found')
 project=Path(__file__).resolve().parent.parent
 for command in [['npm','run','build'],['npm','run','check:site']]:subprocess.run(command,cwd=project,check=True)
 dist=project/'dist';files=sorted(path for path in dist.rglob('*') if path.is_file())
 digest=hashlib.sha256()
 for path in files:
  if path.is_symlink():raise ValueError('Build contains symlink')
  digest.update(path.relative_to(dist).as_posix().encode());digest.update(b'\0');digest.update(path.read_bytes())
 release=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+digest.hexdigest()[:12]
 metadata=json.dumps({'release':release,'contentHash':digest.hexdigest()}).encode()
 options=['-i',str(args.key),'-o','IdentitiesOnly=yes','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=15']
 if args.known_hosts:options+=['-o','UserKnownHostsFile='+str(args.known_hosts)]
 destination=args.user+'@'+args.host
 remote_file='/tmp/howdo-static-'+release+'.tar.gz'
 with tempfile.TemporaryDirectory(prefix='howdo-publish-') as temporary:
  archive=Path(temporary)/'site.tar.gz'
  with tarfile.open(archive,'w:gz') as tar:
   for path in files:tar.add(path,arcname=path.relative_to(dist).as_posix(),recursive=False)
   entry=tarfile.TarInfo('__release.json');entry.size=len(metadata);entry.mode=0o644;tar.addfile(entry,io.BytesIO(metadata))
  subprocess.run(['scp',*options,'-P',str(args.port),str(archive),destination+':'+remote_file],check=True)
  command='python3 - '+ ' '.join(shlex.quote(x) for x in [args.site_dir,release,remote_file])
  subprocess.run(['ssh',*options,'-p',str(args.port),destination,command],input=REMOTE,text=True,check=True)
 actual=json.loads(subprocess.check_output(['curl','-fsS','--max-time','20','https://howdo.icu/__release.json'],text=True))
 if actual['release']!=release:raise RuntimeError('Public website does not show the new release; check network or CDN cache')
 print('Verified https://howdo.icu/ — '+release)


if __name__=='__main__':main()
