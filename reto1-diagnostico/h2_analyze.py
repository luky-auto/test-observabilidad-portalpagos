"""H2: deterministic diagnostics on H1 SQLite; standard library only."""
import argparse
import hashlib
import json
import math
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from statistics import mean

ZONE = timezone(timedelta(hours=-5))
START = datetime(2026, 9, 14, tzinfo=ZONE)
END = START + timedelta(days=7)
APIS = frozenset(('/api/saldos','/api/movimientos','/api/pagos/iniciar',
                  '/api/pagos/confirmar','/api/reportes/extracto'))
CONFIRM = '/api/pagos/confirmar'


def percentile(values, q=.95):
    """Nearest rank: sorted[ceil(q*n)-1], no interpolation; nulls excluded."""
    values = sorted(v for v in values if v is not None)
    if not 0 < q <= 1:
        raise ValueError('invalid_quantile')
    return values[math.ceil(q*len(values))-1] if values else None


def classify(status, win32=0):
    if status is None:
        return 'unknown'
    if status >= 500:
        return 'server_error'
    if win32 not in (0,None):
        return 'transport_error'
    if 200 <= status < 400:
        return 'http_success'
    if 400 <= status < 500:
        return 'client_error'
    return 'other'


def local(value):
    dt=datetime.fromisoformat(value)
    if dt.tzinfo is None:
        raise ValueError('timestamp_requires_offset')
    return dt.astimezone(ZONE)


def ref(row):
    return {k:row[k] for k in ('file','line_start','line_end','bogota')}


def stats(rows):
    classes=Counter(classify(r['status'],r['win32']) for r in rows)
    n=len(rows)
    return {'requests':n,'classification':dict(sorted(classes.items())),
            'http_success_pct':100*classes['http_success']/n if n else None,
            'p95_iis_ms':percentile([r['latency'] for r in rows]),
            'latency_samples':sum(r['latency'] is not None for r in rows)}


def windows(rows, start=START, end=END, minutes=5):
    buckets=defaultdict(list)
    for r in rows:
        dt=local(r['bogota'])
        if start <= dt < end:
            buckets[int((dt-start).total_seconds()//(minutes*60))].append(r)
    result=[]
    for i in range(math.ceil((end-start).total_seconds()/(minutes*60))):
        subset=buckets[i]
        st=stats(subset)
        state='unknown' if not subset else 'failed' if st['classification'].get('server_error',0)==len(subset) else 'degraded' if st['classification'].get('server_error',0) else 'no_5xx_observed'
        result.append({'start':(start+timedelta(minutes=minutes*i)).isoformat(),
                       'state':state,**st})
    return result


def sustained(bins, predicate, count=3):
    run=[]
    for b in bins:
        if predicate(b):
            run.append(b)
            if len(run)==count:
                return {'onset_window':run[0]['start'],'confirmed_at':
                        (local(run[-1]['start'])+timedelta(minutes=5)).isoformat()}
        else:
            run=[]
    return None


def offline_interval(http, api):
    rejected=[r for r in http if r['reason']=='AppOffline' and r['status']==503]
    if not rejected:
        return None
    first,last=min(rejected,key=lambda r:r['bogota']),max(rejected,key=lambda r:r['bogota'])
    after=[r for r in api if r['bogota']>last['bogota'] and classify(r['status'],r['win32'])=='http_success']
    recovered=min(after,key=lambda r:r['bogota']) if after else None
    return {'first_503':ref(first),'last_503':ref(last),'first_api_success_after':ref(recovered) if recovered else None,
            'observed_503_records':len(rejected),
            'bracket_seconds':(local(recovered['bogota'])-local(first['bogota'])).total_seconds() if recovered else None}


def regression(points):
    """OLS over (hours, free MB); sensitivity scenarios are not confidence intervals."""
    if len(points)<2:
        raise ValueError('insufficient_points')
    xs,ys=zip(*points)
    mx,my=mean(xs),mean(ys)
    denom=sum((x-mx)**2 for x in xs)
    if denom==0:
        raise ValueError('zero_time_span')
    slope=sum((x-mx)*(y-my) for x,y in points)/denom
    intercept=my-slope*mx
    residual=sum((y-(intercept+slope*x))**2 for x,y in points)
    total=sum((y-my)**2 for y in ys)
    return {'mb_per_hour':slope,'intercept':intercept,'r_squared':1-residual/total if total else None,
            'rmse_mb':math.sqrt(residual/len(points))}


def read_db(path):
    db=sqlite3.connect(path.resolve().as_uri()+'?mode=ro',uri=True)
    db.row_factory=sqlite3.Row
    groups=defaultdict(list)
    try:
        if db.execute('PRAGMA integrity_check').fetchone()[0]!='ok':
            raise ValueError('invalid_database')
        query='SELECT * FROM records ORDER BY utc,source,file,line_start'
        for row in db.execute(query):
            r=dict(row)
            r['data']=json.loads(r.pop('data_json'))
            groups[r['source']].append(r)
    finally:
        db.close()
    return groups,query


def analyze(database, h1_summary, bat):
    g,query=read_db(database)
    manifest=json.loads(h1_summary.read_text(encoding='utf-8'))
    actual=Counter(r['file'] for rows in g.values() for r in rows)
    if sum(actual.values())!=manifest['totals']['accepted'] or any(actual[f['file']]!=f['accepted'] for f in manifest['files']):
        raise ValueError('h1_counts_mismatch')
    req=[]
    for source in ('iis','httperr'):
        for r in g[source]:
            d=r['data']
            r.update(uri=(d.get('cs-uri-stem') or d.get('cs-uri') or '').split('?')[0],status=d['sc-status'],
                     win32=d.get('sc-win32-status'),latency=d.get('time-taken'),reason=d.get('s-reason'))
            if r['in_week']:
                req.append(r)
    api=[r for r in req if r['uri'] in APIS]
    health=[r for r in req if r['uri']=='/health']
    confirm=[r for r in api if r['uri']==CONFIRM]
    catalog={}
    def evidence(id,title,rule,result):
        catalog[id]={'title':title,'rule':rule,'result':result}
    evidence('E-001','Disponibilidad observada por peticion',
        'IIS+HTTPERR, in_week=1; APIs whitelist; success=HTTP 200..399 y Win32 0 o no disponible. No deduplicar fuentes; R10 H1 no encuentra pares.',
        {'api':stats(api),'health':stats(health),'per_endpoint':{p:stats([r for r in api if r['uri']==p]) for p in sorted(APIS)},
         'health_by_source':{s:stats([r for r in health if r['source']==s]) for s in ('iis','httperr')},
         'api_by_source':{s:stats([r for r in api if r['source']==s]) for s in ('iis','httperr')},
         'daily_api':{(START+timedelta(days=i)).date().isoformat():stats([r for r in api if local(r['bogota']).date()==(START+timedelta(days=i)).date()]) for i in range(7)},
         'health_expected_30s':int((END-START).total_seconds()/30),
         'health_missing_vs_30s':int((END-START).total_seconds()/30)-len(health)})
    w=windows(api)
    counts=Counter(b['state'] for b in w)
    observed=len(w)-counts['unknown']
    evidence('E-002','Ventanas de cinco minutos',
        '2016 ventanas semiabiertas; sin peticiones=unknown; todos 5xx=failed; algun 5xx=degraded; resto=no_5xx_observed. No convertir ausencia a caida.',
        {'api_states':dict(sorted(counts.items())), 'health_states':dict(sorted(Counter(b['state'] for b in windows(health)).items())),
         'observed_windows_without_5xx_pct':100*counts['no_5xx_observed']/observed if observed else None,
         'failed_windows':[b for b in w if b['state']=='failed']})
    incident_start=datetime(2026,9,18,tzinfo=ZONE)
    friday=[r for r in confirm if incident_start<=local(r['bogota'])<incident_start+timedelta(days=1)]
    bins=windows(friday,incident_start,incident_start+timedelta(days=1))
    # Thresholds are analytical definitions, not a previously agreed SLO.
    degradation=sustained(bins,lambda b:b['requests']>=10 and b['p95_iis_ms'] is not None and b['p95_iis_ms']>2000)
    first500=min((r for r in friday if r['status']>=500),key=lambda r:r['bogota'])
    first_any=min((r for r in api if r['bogota'].startswith('2026-09-18') and r['status']>=500),key=lambda r:r['bogota'])
    outage=offline_interval([r for r in req if r['source']=='httperr'],api)
    recovered=outage['first_api_success_after']['bogota']
    evidence('E-003','Transiciones del viernes',
        'Confirmacion: 3 ventanas consecutivas con n>=10 y p95>2000ms; separar primer 5xx diario del primer 5xx de confirmar. AppOffline delimita evidencia de caida; primera API 2xx/3xx posterior delimita recuperacion.',
        {'degradation':degradation,'sensitivity_p95_threshold_ms':{str(t):sustained(bins,lambda b,t=t:b['requests']>=10 and b['p95_iis_ms'] is not None and b['p95_iis_ms']>t) for t in (1500,2000,3000)},
         'first_api_5xx_friday':ref(first_any),'first_confirm_5xx_friday':ref(first500),'offline':outage,
         'confirmed_only_outage_complement_week_pct':100*(1-outage['bracket_seconds']/(END-START).total_seconds()),
         'recovery_30m':stats([r for r in api if local(recovered)<=local(r['bogota'])<local(recovered)+timedelta(minutes=30)]),
         'friday_confirm_bins':[b for b in bins if 'T11:' in b['start'] or 'T12:' in b['start'] or 'T13:' in b['start'] or 'T14:' in b['start'] or 'T15:' in b['start']]})
    events={}
    for label,predicate in {
        'deployment':lambda d:d['ProviderName']=='AndinaDeploy' and d['Id']==1000,
        'storage_move':lambda d:d['ProviderName']=='AndinaDeploy' and d['Id']==1001,
        'oom':lambda d:'OutOfMemoryException' in d['Message'],
        'runtime_termination':lambda d:d['ProviderName']=='.NET Runtime' and d['Id']==1026,
        'pool_disabled':lambda d:d['ProviderName']=='Microsoft-Windows-WAS' and d['Id']==5002,
        'was_failure':lambda d:d['ProviderName']=='Microsoft-Windows-WAS' and d['Id']==5011,
        'disk_warning':lambda d:d['Id']==2013,
        'dcom':lambda d:d['Id']==10016,
        'reset_stop':lambda d:d['Id']==3201,
        'reset_start':lambda d:d['Id']==3202,
        'task_completed':lambda d:d['ProviderName']=='Microsoft-Windows-TaskScheduler' and d['Id']==201,
        'dump_report':lambda d:d['ProviderName']=='Windows Error Reporting'
    }.items():
        selected=[r for r in g['events'] if predicate(r['data'])]
        events[label]={'count':len(selected),'first':ref(selected[0]) if selected else None,'last':ref(selected[-1]) if selected else None,
                       'references':[ref(r) for r in selected] if len(selected)<=14 else [ref(r) for r in selected[:2]+selected[-2:]]}
    evidence('E-004','Eventos correlacionados','Filtros por ProviderName/Id y presencia literal OutOfMemoryException; no publicar mensajes o identidades.',events)
    metrics=[]
    for r in g['metrics']:
        vals={k.split('\\')[-1]:v for k,v in r['data'].items()}
        r['m']=vals
        metrics.append(r)
    daily={}
    for i in range(7):
        day=(START+timedelta(days=i)).date().isoformat()
        subset=[r for r in metrics if r['bogota'].startswith(day)]
        daily[day]={key:{'min':min(r['m'][key] for r in subset if r['m'][key] is not None),
                       'max':max(r['m'][key] for r in subset if r['m'][key] is not None),
                       'last':subset[-1]['m'][key]} for key in ('Private Bytes','Available MBytes','% Processor Time','% Free Space','Free Megabytes')}
    peak=max(metrics,key=lambda r:r['m']['Private Bytes'] or 0)
    early=next(r for r in metrics if (r['m']['Private Bytes'] or 0)>=1024**3)
    evidence('E-005','Memoria y señales tempranas','Min/max/cierre diario Perfmon; primer Private Bytes>=1GiB (umbral analitico); p95 nearest rank por dia confirmar.',
        {'daily_metrics':daily,'first_memory_ge_1GiB':ref(early),'peak_memory':{**ref(peak),'bytes':peak['m']['Private Bytes'],'available_mb':peak['m']['Available MBytes']},
         'confirm_daily':{day:stats([r for r in confirm if r['bogota'].startswith(day)]) for day in daily},
         'first_disk_below_20pct':ref(next(r for r in metrics if r['m']['% Free Space']<20)),
         'first_disk_below_10pct':ref(next(r for r in metrics if r['m']['% Free Space']<10))})
    last=metrics[-1]
    end=local(last['bogota'])
    forecast=[]
    for hours in (24,48,72,96):
        subset=[r for r in metrics if end-timedelta(hours=hours)<=local(r['bogota'])<=end]
        fit=regression([((local(r['bogota'])-end).total_seconds()/3600,r['m']['Free Megabytes']) for r in subset])
        remaining=last['m']['Free Megabytes']/-fit['mb_per_hour'] if fit['mb_per_hour']<0 else None
        forecast.append({'lookback_hours':hours,'samples':len(subset),**fit,'hours_to_zero_from_last':remaining,
                         'conditional_zero_bogota':(end+timedelta(hours=remaining)).isoformat() if remaining else None,
                         'first_ref':ref(subset[0]),'last_ref':ref(last)})
    evidence('E-006','Riesgo de disco y extrapolacion condicional',
        'OLS espacio libre MB contra horas, ultimas 24/48/72/96h; anclar proyeccion al ultimo MB observado; sin limpiezas, cambios de carga ni de logging. Sensibilidad, no intervalo probabilistico.',
        {'last':{**ref(last),'free_mb':last['m']['Free Megabytes'],'free_pct':last['m']['% Free Space']},'scenarios':forecast})
    # Inspect only fixed command patterns. Never serialize BAT lines or credentials.
    lines=bat.read_text(encoding='utf-8').splitlines()
    dump_folder=next((s.split('=',1)[1].strip() for s in lines if s.startswith('set CRASHDIR=')),None)
    wer=[r for r in g['events'] if r['data']['ProviderName']=='Windows Error Reporting']
    patterns={'retention':lambda s:s.lower().startswith('forfiles '),'reset':lambda s:s.lower().startswith('iisreset '),
              'delete_dumps':lambda s:s.lower().startswith('del ') and '%CRASHDIR%' in s,
              'success_text':lambda s:s.lower().startswith('echo Proceso OK'.lower()),
              'unconditional_exit_zero':lambda s:s.lower()=='exit /b 0',
              'old_drive_invocation':lambda s:s.startswith('REM') and 'D:' in s,
              'dump_directory_assignment':lambda s:s.startswith('set CRASHDIR=')}
    evidence('E-007','Mantenimiento y trazabilidad',
        'Inspeccion estatica por patrones del BAT, sin ejecutarlo ni serializar lineas. Confrontar R11 H1 y E-004 task/reset/storage_move/dump_report.',
        {'bat_references':{key:[{'file':'scripts/mantenimiento_diario.bat','line':i} for i,s in enumerate(lines,1) if test(s)] for key,test in patterns.items()},
         'undated_log_records':len(g['maintenance']),
         'documented_dump_folder_matches_wer':all((dump_folder+'\\').lower() in r['data']['Message'].lower() for r in wer) if dump_folder and wer else None})
    evidence('E-008','Reportes humanos','Tickets conservados sin asumir que notas de cierre prueban causalidad.',
        [{'id':r['data']['Id'],**ref(r)} for r in g['tickets']])
    scan_paths=['/.env','/wp-login.php','/admin/config.php','/phpmyadmin/index.php']
    evidence('E-009','Sondeos de rutas ajenas a la aplicacion','Excluir estas rutas del indicador API; no inferir intrusion ni DDoS solo de peticiones.',
        {p:stats([r for r in req if r['uri']==p]) for p in scan_paths})
    return {'version':1,'window':[START.isoformat(),END.isoformat()],
            'h1_summary_sha256':hashlib.sha256(h1_summary.read_bytes()).hexdigest(),
            'source_query':query,'api_scope':sorted(APIS),'percentile':'nearest-rank ceil(0.95*n)',
            'timezone_limit':'Eventos/tickets Bogota supuesto heredado H1; IIS/HTTPERR UTC por formato.',
            'evidence':catalog}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--database',type=Path,default=Path('work-private/h1/normalized.sqlite'))
    p.add_argument('--h1-summary',type=Path,default=Path('work-private/h1/summary.json'))
    p.add_argument('--bat',type=Path,default=Path('input-private/kit_prueba_portalpagos/scripts/mantenimiento_diario.bat'))
    p.add_argument('--output',type=Path,default=Path('work-private/h2/evidence.json'))
    a=p.parse_args()
    project=Path(__file__).resolve().parents[1]
    if not a.output.resolve().is_relative_to(project/'work-private'):
        p.error('output must be under work-private')
    result=analyze(a.database,a.h1_summary,a.bat)
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(result,ensure_ascii=False,sort_keys=True,indent=2,allow_nan=False)+'\n',encoding='utf-8')
    print('H2: 9 evidence groups generated; no raw rows or BAT text published.')


if __name__=='__main__':
    main()
