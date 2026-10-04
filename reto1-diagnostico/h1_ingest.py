"""H1 only: reproducible quality inventory; no incident diagnosis. Standard library."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import sqlite3
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

UTC = timezone.utc
# Explicit fixed offset for the supplied September 2026 window in America/Bogota.
# No dependency on host timezone or an OS timezone database.
BOGOTA = timezone(timedelta(hours=-5), "America/Bogota")
START = datetime(2026, 9, 14, tzinfo=BOGOTA)
END = datetime(2026, 9, 21, tzinfo=BOGOTA)
EVENT_FIELDS = "TimeCreated LogName ProviderName Id LevelDisplayName MachineName Message".split()
TICKET_FIELDS = "Id FechaHoraReporte Prioridad Grupo Descripcion Estado NotaCierre".split()
RULES = {
    "R01": "UTF-8 estricto con BOM opcional; error de codificacion aborta, sin sustitucion silenciosa.",
    "R02": "Archivo identico por SHA256 dentro de una fuente: conservar primero por nombre mas corto y orden lexical; inventariar todas las copias.",
    "R03": "W3C: cada #Fields inicia un esquema; cardinalidad exacta y nombres unicos; nunca inferir columnas por posicion fija.",
    "R04": "CSV estricto con coma y comillas; multilinea permitida; conservar lineas fisicas inicial/final; cardinalidad exacta.",
    "R05": "Fecha invalida, esquema incompatible, cardinalidad o numero obligatorio invalido: cuarentena por referencia, sin reparar.",
    "R06": "Guion W3C y celda CSV vacia o solo espacios: null. Numeros opcionales faltantes se conservan y cuentan; no imputar ceros. HTTPERR sin peticion HTTP se conserva sin estado/metodo/URI y no participa en matching de peticiones.",
    "R07": "IIS W3C y HTTPERR: UTC segun formato oficial. Perfmon: SA Pacific Standard Time(300), UTC-05. Eventos/tickets sin offset: supuesto explicito Bogota segun LEEME, contrastado pero no demostrado.",
    "R08": "Normalizar a ISO8601 UTC y America/Bogota UTC-05; conservar timestamp original. Ventana semiabierta semanal; fuera de ventana se conserva y se marca.",
    "R09": "Filas identicas dentro de fuente solo se marcan como candidatas y se conservan: no hay identificador global de peticion/evento.",
    "R10": "IIS/HTTPERR: coincidencia por segundo UTC, metodo, URI sin query, estado e IP servidor es candidata, no prueba de identidad; no unir ni eliminar.",
    "R11": "Mantenimiento: texto sin fecha se conserva como registro no temporal; no inferir ejecuciones ni exito.",
    "R12": "Publicar solo conteos, hashes de archivo, esquemas, rangos y referencias; filas normalizadas y cuarentena quedan en work-private.",
}


def dumps(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, allow_nan=False)


def sha256(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def timestamp(raw, kind):
    fmt = {"iis": "%Y-%m-%d %H:%M:%S", "httperr": "%Y-%m-%d %H:%M:%S",
           "events": "%Y-%m-%d %H:%M:%S", "metrics": "%m/%d/%Y %H:%M:%S.%f",
           "tickets": "%Y-%m-%d %H:%M"}[kind]
    value = datetime.strptime(raw, fmt).replace(tzinfo=UTC if kind in ("iis", "httperr") else BOGOTA)
    return value.astimezone(UTC).isoformat(), value.astimezone(BOGOTA).isoformat(), START <= value < END


def number(value, integer=False, minimum=0, maximum=None):
    if value is None:
        return None
    if integer and not re.fullmatch(r"\d+", value):
        raise ValueError("invalid_integer")
    if not integer and not re.fullmatch(r"\d+(?:\.\d+)?", value):
        raise ValueError("invalid_decimal")
    parsed = int(value) if integer else float(value)
    if not math.isfinite(parsed) or parsed < minimum or (maximum is not None and parsed > maximum):
        raise ValueError("numeric_range")
    return parsed


def validate_schema(fields, kind):
    if len(fields) != len(set(fields)):
        return False
    if kind in ("iis", "httperr"):
        required = {"date", "time", "cs-method", "sc-status", "s-ip",
                    "cs-uri-stem" if kind == "iis" else "cs-uri"}
        if kind == "httperr":
            required.add("s-reason")
        return required <= set(fields)
    if kind == "events":
        return fields == EVENT_FIELDS
    if kind == "tickets":
        return fields == TICKET_FIELDS
    if kind == "metrics":
        suffixes = [r"\Processor(_Total)\% Processor Time", r"\Memory\Available MBytes",
                    r"\LogicalDisk(C:)\% Free Space", r"\LogicalDisk(C:)\Free Megabytes",
                    r"\Process(w3wp)\Private Bytes", r"\Web Service(PortalPagos)\Current Connections"]
        return (len(fields) == 7 and fields[0] == "(PDH-CSV 4.0) (SA Pacific Standard Time)(300)"
                and all(field.endswith(suffix) for field, suffix in zip(fields[1:], suffixes)))
    return False


def records(path, kind, stats):
    """Yield (physical start/end, schema line, values, structural issue)."""
    with path.open(encoding="utf-8-sig", errors="strict", newline="") as stream:
        if kind in ("iis", "httperr", "maintenance"):
            fields, schema_line = [], None
            for line_no, raw in enumerate(stream, 1):
                stats["physical_lines"] = line_no
                text = raw.strip()
                if not text:
                    stats["blank_lines"] += 1
                    continue
                if kind == "maintenance":
                    yield line_no, line_no, None, {"text": text}, None
                    continue
                if text.startswith("#"):
                    stats["comment_lines"] += 1
                    if text.startswith("#Fields:"):
                        fields = text[8:].split()
                        schema_line = line_no
                        stats["schemas"].append({"line": line_no, "fields": fields,
                                                  "valid": validate_schema(fields, kind)})
                    continue
                tokens = text.split()
                error = None
                if not validate_schema(fields, kind):
                    error = "missing_or_invalid_schema"
                elif len(tokens) != len(fields):
                    error = "field_count"
                yield line_no, line_no, schema_line, dict(zip(fields, tokens)), error
        else:
            reader = csv.reader(stream, strict=True)
            try:
                fields = next(reader)
            except StopIteration:
                raise ValueError("empty_csv") from None
            stats["schemas"].append({"line": 1, "fields": fields, "valid": validate_schema(fields, kind)})
            previous = reader.line_num
            while True:
                try:
                    values = next(reader)
                except StopIteration:
                    break
                except csv.Error:
                    # Cannot reliably recover row boundaries after malformed quoting.
                    raise ValueError("csv_syntax_abort") from None
                start, previous = previous + 1, reader.line_num
                stats["physical_lines"] = previous
                if not values:
                    stats["blank_lines"] += 1
                    continue
                error = None if validate_schema(fields, kind) else "invalid_csv_schema"
                if len(values) != len(fields):
                    error = "field_count"
                yield start, previous, 1, dict(zip(fields, values)), error
            stats["physical_lines"] = reader.line_num


def normalize(values, kind):
    data = {k: None if not v.strip() or (v == "-" and kind in ("iis", "httperr")) else v for k, v in values.items()}
    warnings = []
    if kind == "maintenance":
        return data, None, None, None, None, ["missing_timestamp"]
    if kind in ("iis", "httperr"):
        raw = f'{data.get("date")} {data.get("time")}'
        uri_field = "cs-uri-stem" if kind == "iis" else "cs-uri"
        required_values = ("sc-status", "cs-method", uri_field, "s-ip") if kind == "iis" else ("s-ip", "s-reason")
        for field in required_values:
            if data.get(field) is None:
                raise ValueError("missing_required_value")
        for field in ("sc-status", "sc-substatus", "sc-win32-status", "time-taken", "s-port", "c-port"):
            if field in data:
                data[field] = number(data[field], integer=True, minimum=100 if field == "sc-status" else 0,
                                     maximum=599 if field == "sc-status" else 65535 if field.endswith("-port") else None)
                if data[field] is None:
                    warnings.append("missing_numeric:" + field)
        if kind == "httperr" and any(data.get(k) is None for k in ("sc-status", "cs-method", uri_field)):
            warnings.append("incomplete_http_request")
    elif kind == "events":
        raw = data["TimeCreated"]
        if any(data[k] is None for k in ("TimeCreated", "LogName", "ProviderName", "Id")):
            raise ValueError("missing_required_value")
        data["Id"] = number(data["Id"], integer=True)
    elif kind == "tickets":
        raw = data["FechaHoraReporte"]
        if data["Id"] is None or raw is None:
            raise ValueError("missing_required_value")
    else:
        raw = next(iter(data.values()))
        for field in list(data)[1:]:
            data[field] = number(data[field], maximum=100 if "%" in field else None)
            if data[field] is None:
                warnings.append("missing_numeric:" + field)
    try:
        utc, local, in_week = timestamp(raw, kind)
    except (ValueError, TypeError):
        raise ValueError("invalid_timestamp") from None
    if kind in ("events", "tickets"):
        warnings.append("timezone_assumed_bogota")
    return data, raw, utc, local, in_week, warnings


def discover(root):
    patterns = [("iis", "logs/iis/W3SVC2/*.log"), ("httperr", "logs/httperr/*.log"),
                ("events", "eventos/*.csv"), ("metrics", "metricas/*.csv"),
                ("tickets", "tickets/*.csv"), ("maintenance", "scripts/mantenimiento.log")]
    found = []
    for kind, pattern in patterns:
        paths = sorted(root.glob(pattern), key=lambda p: (len(p.name), p.name))
        if not paths:
            raise ValueError("missing_source:" + kind)
        for path in paths:
            if not path.is_file() or not path.resolve().is_relative_to(root.resolve()):
                raise ValueError("unsafe_input_path")
            found.append((kind, path))
    return found


def create_database(path):
    db = sqlite3.connect(path)
    db.executescript("""
        DROP TABLE IF EXISTS records;
        DROP TABLE IF EXISTS issues;
        CREATE TABLE records (
          source TEXT, file TEXT, line_start INTEGER, line_end INTEGER, schema_line INTEGER,
          raw_timestamp TEXT, utc TEXT, bogota TEXT, in_week INTEGER,
          data_json TEXT, warnings_json TEXT, signature TEXT, http_key TEXT);
        CREATE TABLE issues(file TEXT, line_start INTEGER, line_end INTEGER, rule TEXT, reason TEXT);
    """)
    return db


def refs(db, query, args=()):
    return [dict(zip([c[0] for c in cursor.description], row))
            for cursor in [db.execute(query, args)] for row in cursor]


def aggregate(db):
    duplicates = refs(db, """SELECT source, count(*) AS groups, sum(n-1) AS extra_rows
        FROM (SELECT source, signature, count(*) n FROM records
        GROUP BY source, signature HAVING count(*) > 1) GROUP BY source""")
    duplicate_examples = refs(db, """SELECT r.source,r.file,r.line_start,r.line_end FROM records r
        JOIN (SELECT source,signature FROM records GROUP BY source,signature HAVING count(*)>1) d
        ON r.source=d.source AND r.signature=d.signature ORDER BY r.source,r.file,r.line_start LIMIT 10""")
    cross = refs(db, """SELECT count(*) AS candidate_pairs,
        count(DISTINCT a.rowid) AS iis_rows, count(DISTINCT b.rowid) AS httperr_rows
        FROM records a JOIN records b ON a.http_key=b.http_key
        WHERE a.source='iis' AND b.source='httperr'""")[0]
    cross["examples"] = refs(db, """SELECT a.file AS iis_file,a.line_start AS iis_line,
        b.file AS httperr_file,b.line_start AS httperr_line,a.utc
        FROM records a JOIN records b ON a.http_key=b.http_key
        WHERE a.source='iis' AND b.source='httperr' ORDER BY a.file,a.line_start,b.line_start LIMIT 5""")
    metric_times = [datetime.fromisoformat(r[0]) for r in db.execute("SELECT utc FROM records WHERE source='metrics' ORDER BY utc")]
    unique = set(metric_times)
    expected = {START.astimezone(UTC) + timedelta(minutes=5*i) for i in range(2016)}
    cadence = {"rule": "R08; expected=2016 instantes cada 5 minutos en semana local",
               "rows": len(metric_times), "unique_timestamps": len(unique),
               "missing_expected_slots": len(expected-unique), "unexpected_slots": len(unique-expected),
               "non_300_second_intervals": sum((b-a).total_seconds()!=300 for a,b in zip(metric_times,metric_times[1:]))}
    warning_refs = refs(db, """SELECT file,line_start,line_end,j.value AS warning FROM records,
        json_each(warnings_json) j WHERE j.value NOT IN ('timezone_assumed_bogota','missing_timestamp')
        ORDER BY file,line_start,j.value""")
    return {"same_source_candidates_retained": duplicates, "same_source_examples": duplicate_examples,
            "cross_source_rule": "R10", "cross_source_candidates_retained": cross, "metric_cadence": cadence,
            "warning_references":warning_refs}


def temporal_contrast(db):
    """Compare clock interpretations; not a causal incident timeline."""
    anchor = db.execute("""SELECT file,line_start,utc FROM records WHERE source='httperr'
        AND json_extract(data_json,'$."s-reason"')='AppOffline' ORDER BY utc,file,line_start LIMIT 1""").fetchone()
    evidence = {"rule": "R07; comparar evento WAS 5002 mas cercano al primer AppOffline bajo dos interpretaciones",
                "conclusion": "Compatibilidad temporal no demuestra zona de exportacion ni causalidad.",
                "events_and_tickets_timezone": "assumed_bogota_not_proven"}
    if anchor:
        target = datetime.fromisoformat(anchor[2])
        candidates = list(db.execute("""SELECT file,line_start,raw_timestamp,utc FROM records WHERE source='events'
            AND json_extract(data_json,'$.Id')=5002 AND json_extract(data_json,'$.ProviderName')='Microsoft-Windows-WAS'"""))
        evidence["httperr_anchor"] = dict(zip(("file","line","utc"),anchor))
        if candidates:
            row = min(candidates, key=lambda r: abs((datetime.fromisoformat(r[3])-target).total_seconds()))
            evidence["event_anchor"] = {"file":row[0],"line":row[1],"raw_timestamp":row[2],
                 "delta_seconds_if_bogota":(datetime.fromisoformat(row[3])-target).total_seconds(),
                 "delta_seconds_if_utc":(datetime.strptime(row[2],"%Y-%m-%d %H:%M:%S").replace(tzinfo=UTC)-target).total_seconds()}
        evidence["nearby_tickets_if_bogota"] = refs(db, """SELECT file,line_start,raw_timestamp,utc FROM records
            WHERE source='tickets' AND abs(unixepoch(utc)-unixepoch(?))<=1800 ORDER BY utc""", (anchor[2],))
        evidence["nearest_metric_if_header_zone"] = refs(db, """SELECT file,line_start,raw_timestamp,utc FROM records
            WHERE source='metrics' ORDER BY abs(unixepoch(utc)-unixepoch(?)),utc LIMIT 1""", (anchor[2],))
        evidence["nearest_iis_using_w3c_utc"] = refs(db, """SELECT file,line_start,raw_timestamp,utc,bogota FROM records
            WHERE source='iis' ORDER BY abs(unixepoch(utc)-unixepoch(?)),utc,file,line_start LIMIT 1""", (anchor[2],))
    return evidence


def run(root, output):
    root, output = root.resolve(), output.resolve()
    project = Path(__file__).resolve().parents[1]
    if not output.is_relative_to(project / "work-private") or output.is_relative_to(root) or root.is_relative_to(output):
        raise ValueError("output_must_be_inside_project_work_private_and_disjoint_from_input")
    output.mkdir(parents=True, exist_ok=True)
    # Remove stale completion marker before any operation that could fail.
    summary_path = output / "summary.json"
    if summary_path.is_symlink() or (output / "normalized.sqlite").is_symlink():
        raise ValueError("output_file_symlink_not_allowed")
    summary_path.unlink(missing_ok=True)
    sources = discover(root)
    before = {p: sha256(p) for _, p in sources}
    db = create_database(output / "normalized.sqlite")
    inventory, seen = [], {}
    try:
        for kind, path in sources:
            relative = path.relative_to(root).as_posix()
            stat = {"source":kind,"file":relative,"bytes":path.stat().st_size,"sha256":before[path],
                    "copy_name_hint":bool(re.search(r"copia|copy",path.name,re.I)),
                    "physical_lines":0,"blank_lines":0,"comment_lines":0,"schemas":[],
                    "input_rows":0,"accepted":0,"rejected":0,"duplicate_file_rows":0,
                    "in_week":0,"outside_week":0,"undated":0,"warnings":Counter(),"reasons":Counter(),
                    "first_utc":None,"last_utc":None,"first_bogota":None,"last_bogota":None,
                    "first_ref":None,"last_ref":None,"timestamp_backsteps":0}
            key = (kind, before[path])
            if key in seen:
                original = seen[key]
                stat.update({k:original[k] for k in ("physical_lines","blank_lines","comment_lines","schemas","input_rows")})
                stat["duplicate_of"] = original["file"]
                stat["duplicate_file_rows"] = original["input_rows"]
                inventory.append(stat)
                continue
            seen[key] = stat
            previous_time = None
            for start, end, schema, values, error in records(path, kind, stat):
                stat["input_rows"] += 1
                try:
                    if error:
                        raise ValueError(error)
                    data, raw, utc, local, in_week, warnings = normalize(values,kind)
                except ValueError as exc:
                    reason = str(exc)
                    stat["rejected"] += 1
                    stat["reasons"][reason] += 1
                    db.execute("INSERT INTO issues VALUES(?,?,?,?,?)",(relative,start,end,"R05",reason))
                    continue
                stat["accepted"] += 1
                stat["warnings"].update(warnings)
                stat["undated" if utc is None else "in_week" if in_week else "outside_week"] += 1
                if utc:
                    if previous_time and utc < previous_time:
                        stat["timestamp_backsteps"] += 1
                    previous_time = utc
                    for edge, comparison in (("first", lambda a,b:a<b),("last",lambda a,b:a>b)):
                        if stat[edge+"_utc"] is None or comparison(utc,stat[edge+"_utc"]):
                            stat[edge+"_utc"], stat[edge+"_bogota"] = utc, local
                            stat[edge+"_ref"] = {"line_start":start,"line_end":end}
                signature = hashlib.sha256(dumps(data).encode()).hexdigest()
                http_key = None
                if kind in ("iis","httperr") and all(data.get(k) is not None for k in
                        ("cs-uri-stem" if kind == "iis" else "cs-uri", "sc-status", "cs-method", "s-ip")):
                    uri = data["cs-uri-stem" if kind=="iis" else "cs-uri"].split("?",1)[0]
                    http_key = dumps([utc,data["cs-method"],uri,data["sc-status"],data["s-ip"]])
                db.execute("INSERT INTO records VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                           (kind,relative,start,end,schema,raw,utc,local,in_week,dumps(data),dumps(warnings),signature,http_key))
            assert stat["input_rows"] == stat["accepted"] + stat["rejected"]
            inventory.append(stat)
        db.executescript("CREATE INDEX record_signature ON records(source,signature); CREATE INDEX http_match ON records(source,http_key); CREATE INDEX record_time ON records(source,utc);")
        db.commit()
        quality = aggregate(db)
        quality["quarantine"] = refs(db,"SELECT * FROM issues ORDER BY file,line_start")
        contrast = temporal_contrast(db)
        if any(sha256(path)!=digest for path,digest in before.items()):
            raise ValueError("input_changed_during_run")
        totals = {k:sum(s[k] for s in inventory) for k in ("input_rows","accepted","rejected","duplicate_file_rows","in_week","outside_week","undated")}
        assert totals["input_rows"] == totals["accepted"]+totals["rejected"]+totals["duplicate_file_rows"]
        assert totals["accepted"] == totals["in_week"]+totals["outside_week"]+totals["undated"]
        summary = {"contract_version":1,"scope":"H1 quality only","input_unchanged":True,
                   "window_bogota":[START.isoformat(),END.isoformat()],"end_exclusive":True,
                   "rules":RULES,"totals":totals,"files":inventory,"quality":quality,"temporal_contrast":contrast,
                   "not_read":["scripts/mantenimiento_diario.bat","alertas/alerta_ejemplo.json","enunciado DOCX"],
                   "limitations":["No disponibilidad, causa raiz ni pronosticos.","Sin ID global no se demuestra identidad entre fuentes.",
                                   "Eventos y tickets carecen de offset; conversion provisional.","Cobertura de registros no demuestra continuidad de servicio."]}
        summary_path.write_text(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2,allow_nan=False)+"\n",encoding="utf-8")
        return summary
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input",type=Path,default=Path("input-private/kit_prueba_portalpagos"))
    parser.add_argument("--output",type=Path,default=Path("work-private/h1"))
    args = parser.parse_args()
    try:
        summary = run(args.input,args.output)
    except (ValueError,UnicodeError,csv.Error,sqlite3.Error,OSError) as exc:
        # Never print raw data or exception text that might contain input values.
        parser.exit(1,f"H1 abortado ({type(exc).__name__}); no usar salidas parciales. Revisar contrato/rutas.\n")
    print(dumps(summary["totals"]))


if __name__ == "__main__":
    main()
