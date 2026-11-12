#!/usr/bin/env python3
"""Read-only native evidence. Never copies or publishes the proprietary executable."""
import struct, subprocess, re, json, sys, hashlib
from pathlib import Path
if len(sys.argv) != 2:
 raise SystemExit('Usage: native_calls.py /path/to/your/Spotify/executable')
p=Path(sys.argv[1])
d=p.read_bytes();off=32;segments=[]
for _ in range(struct.unpack_from('<I',d,16)[0]):
 cmd,size=struct.unpack_from('<II',d,off)
 if cmd==0x19:
  vm,vs,fo,fs=struct.unpack_from('<QQQQ',d,off+24);segments.append((vm,fs,fo))
 off+=size
def pos(a):
 for vm,fs,fo in segments:
  if vm<=a<vm+fs:return a-vm+fo
 raise ValueError(hex(a))
def string(a):
 o=pos(a);return d[o:d.index(0,o)].decode()
def selector(a):
 try:
  w,l=struct.unpack_from('<II',d,pos(a))
  if w&0x9f00001f!=0x90000001 or l&0xffc003ff!=0xf9400021:return None
  imm=((w>>29)&3)|(((w>>5)&0x7ffff)<<2)
  if imm&(1<<20):imm-=1<<21
  addr=(a&~4095)+(imm<<12)+((l>>10)&0xfff)*8
  ptr=struct.unpack_from('<Q',d,pos(addr))[0]
  if ptr>0x10000000000:ptr=(ptr&0xfffffffff)+0x100000000
  return string(ptr)
 except (ValueError,UnicodeDecodeError):return None
ranges={
 'queueTrackPlayNext:':(0x109f84c74,0x109f84eb0),
 'PlayNextAction mutation':(0x106f160f8,0x106f16310),
 'snackbar bindView/action':(0x10a1d3f84,0x10a1d40c0),
 'snackbar show/hide':(0x10a1d6088,0x10a1d6554),
 'addToQueue completion':(0x109f8804c,0x109f8816c),
}
result={'binarySHA256':hashlib.sha256(d).hexdigest(),'source':'cached Spotify 9.1.94 main executable','type':'static native binary analysis, not execution','methods':{}}
for name,(a,b) in ranges.items():
 out=subprocess.check_output(['xcrun','llvm-objdump','-d',f'--start-address={hex(a)}',f'--stop-address={hex(b)}',str(p)],text=True)
 calls=[]
 for m in re.finditer(r'^([0-9a-f]+):.*\bbl\s+(0x[0-9a-f]+)',out,re.M):
  s=selector(int(m[2],16))
  if s:calls.append({'call':m[1],'selector':s})
 result['methods'][name]=calls
print(json.dumps(result,indent=2))
