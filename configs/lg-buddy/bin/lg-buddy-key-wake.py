#!/usr/bin/env python3
"""LG Buddy: detecta SO Shift/Ctrl pressionado em TECLADO FISICO (ignora mouse, movimento, rolagem e dispositivos virtuais).
Fase 1 (LOG_ONLY=1): apenas registra 'gatilho' no journal; nao aciona a TV. Nunca registra qual tecla (so o tipo)."""
import os,re,struct,select,time,sys,errno,subprocess
LOG_ONLY=os.environ.get("LOG_ONLY","1")=="1"
TRIG={29:"ctrl",97:"ctrl",42:"shift",54:"shift"}          # KEY_LEFTCTRL/RIGHTCTRL/LEFTSHIFT/RIGHTSHIFT
STATE="/run/user/%d/lg_buddy/screen_off_by_us"%os.getuid()
EXCL=re.compile(r"Power Button|Sleep Button|Lid Switch|Video Bus|Yubico|ydotool|RustDesk|uinput|virtual|CEC",re.I)
COOLDOWN=5.0
def log(m): print(m,flush=True)
def scan():
    devs={}
    for b in open("/proc/bus/input/devices").read().strip().split("\n\n"):
        n=re.search(r'N: Name="(.*)"',b); ph=re.search(r"P: Phys=(.*)",b); h=re.search(r"H: Handlers=(.*)",b); bus=re.search(r"Bus=(\w+)",b)
        k=re.search(r"B: KEY=(.*)",b)
        if not(n and ph and h and bus and k): continue
        if EXCL.search(n.group(1)) or not ph.group(1).strip() or bus.group(1)=="0006": continue   # virtual/uinput: sem phys
        ev=re.search(r"event(\d+)",h.group(1))
        if not ev: continue
        codes=set(); words=k.group(1).split()
        for i,w in enumerate(reversed(words)):
            v=int(w,16)
            for bit in range(64):
                if v>>bit&1: codes.add(i*64+bit)
        if not all(c in codes for c in range(30,39)): continue    # precisa ter letras (teclado de verdade)
        rel=re.search(r"B: REL=(\w+)",b)
        if rel and int(rel.group(1),16)&0b11: continue            # tem REL_X/REL_Y = mouse (mesmo que emita teclas): fora
        devs["/dev/input/event"+ev.group(1)]=n.group(1)
    return devs
def main():
    fds={}; last_scan=0; last_fire=0
    while True:
        now=time.time()
        if now-last_scan>30 or not fds:
            last_scan=now; want=scan()
            for p in list(fds.values()):
                pass
            cur={v[0]:fd for fd,v in fds.items()}
            for p,n in want.items():
                if p not in cur:
                    try: fd=os.open(p,os.O_RDONLY|os.O_NONBLOCK); fds[fd]=(p,n); log("monitorando teclado fisico: %s"%n)
                    except OSError as e: log("falha ao abrir %s: %s"%(p,e))
            for fd,(p,n) in list(fds.items()):
                if p not in want: os.close(fd); del fds[fd]
        if not fds: time.sleep(5); continue
        try: r,_,_=select.select(list(fds),[],[],5)
        except OSError: last_scan=0; continue
        for fd in r:
            try: d=os.read(fd,24*32)
            except BlockingIOError: continue
            except OSError as e:
                if e.errno in (errno.ENODEV,errno.EBADF): os.close(fd); fds.pop(fd,None); last_scan=0
                continue
            for i in range(0,len(d)-23,24):
                s,u,t,c,v=struct.unpack("llHHi",d[i:i+24])
                if t==1 and v==1 and c in TRIG:
                    now=time.time()
                    if now-last_fire<COOLDOWN: continue
                    last_fire=now
                    off=os.path.exists(STATE)
                    log("gatilho=%s tv_apagada_pelo_lgbuddy=%s modo=%s"%(TRIG[c],off,"LOG_ONLY" if LOG_ONLY else "ACAO"))
                    if not LOG_ONLY and off:
                        r=subprocess.run(["systemctl","--user","start","--no-block","lg-buddy-wake.service"],capture_output=True,text=True)
                        log("acao: lg-buddy-wake.service iniciado rc=%d %s"%(r.returncode,r.stderr.strip()[:80]))
if __name__=="__main__": main()
