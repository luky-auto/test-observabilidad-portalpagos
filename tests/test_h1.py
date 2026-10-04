"""Small synthetic fixtures constructed here; never read the original kit."""
import csv
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("h1", PROJECT / "reto1-diagnostico/h1_ingest.py")
h1 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h1)

IIS_HEADER = "date time s-ip cs-method cs-uri-stem sc-status time-taken"
IIS_ROW = "2026-09-14 05:00:00 192.0.2.1 GET /synthetic 200 12"
HTTP_HEADER = "date time s-ip cs-method cs-uri sc-status s-reason"
METRIC_HEADER = ["(PDH-CSV 4.0) (SA Pacific Standard Time)(300)"] + [r"\\SYNTHETIC" + s for s in
    [r"\Processor(_Total)\% Processor Time",r"\Memory\Available MBytes",r"\LogicalDisk(C:)\% Free Space",
     r"\LogicalDisk(C:)\Free Megabytes",r"\Process(w3wp)\Private Bytes",r"\Web Service(PortalPagos)\Current Connections"]]


class H1Tests(unittest.TestCase):
    def setUp(self):
        private = PROJECT / "work-private"
        private.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="h1-test-",dir=private)
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def write(self,name,text):
        path = self.root / name
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(text,encoding="utf-8")
        return path

    def csv_file(self,name,header,rows):
        path = self.root / name
        path.parent.mkdir(parents=True,exist_ok=True)
        with path.open("w",encoding="utf-8",newline="") as f:
            writer=csv.writer(f)
            writer.writerow(header)
            writer.writerows(rows)
        return path

    def parse(self,path,kind):
        stat={"physical_lines":0,"blank_lines":0,"comment_lines":0,"schemas":[]}
        return list(h1.records(path,kind,stat)),stat

    def test_w3c_changes_schema_inside_file(self):
        p=self.write("change.txt",f"#Fields: {IIS_HEADER}\n{IIS_ROW}\n#Fields: {IIS_HEADER} cs-host\n{IIS_ROW} synthetic.invalid\n")
        rows,stat=self.parse(p,"iis")
        self.assertEqual([r[2] for r in rows],[1,3])
        self.assertNotIn("cs-host",rows[0][3])
        self.assertEqual(rows[1][3]["cs-host"],"synthetic.invalid")
        self.assertEqual(len(stat["schemas"]),2)

    def test_cardinality_quarantinable(self):
        p=self.write("bad.txt",f"#Fields: {IIS_HEADER}\n{IIS_ROW} EXTRA\n")
        self.assertEqual(self.parse(p,"iis")[0][0][-1],"field_count")

    def test_no_header_is_not_guessed(self):
        p=self.write("none.txt",IIS_ROW+"\n")
        self.assertEqual(self.parse(p,"iis")[0][0][-1],"missing_or_invalid_schema")

    def test_duplicate_schema_names_rejected(self):
        self.assertFalse(h1.validate_schema((IIS_HEADER+" date").split(),"iis"))

    def test_reordered_w3c_fields(self):
        fields=IIS_HEADER.split()[::-1]
        p=self.write("order.txt","#Fields: "+" ".join(fields)+"\n"+" ".join(IIS_ROW.split()[::-1])+"\n")
        data=h1.normalize(self.parse(p,"iis")[0][0][3],"iis")[0]
        self.assertEqual(data["sc-status"],200)

    def test_utc_and_semiclosed_week(self):
        self.assertEqual(h1.timestamp("2026-09-14 05:00:00","iis")[1],"2026-09-14T00:00:00-05:00")
        self.assertFalse(h1.timestamp("2026-09-14 04:59:59","iis")[2])
        self.assertTrue(h1.timestamp("2026-09-21 04:59:59","iis")[2])
        self.assertFalse(h1.timestamp("2026-09-21 05:00:00","iis")[2])

    def test_naive_event_uses_documented_assumption(self):
        data=dict(zip(h1.EVENT_FIELDS,["2026-09-14 00:00:00","System","Synthetic", "1","Info","SYNTHETIC","fixture"]))
        result=h1.normalize(data,"events")
        self.assertEqual(result[2],"2026-09-14T05:00:00+00:00")
        self.assertIn("timezone_assumed_bogota",result[-1])

    def test_whitespace_metric_is_null_not_zero(self):
        data=dict(zip(METRIC_HEADER,["09/14/2026 00:00:00.000","1.5","2048","25.0","1000"," ","0"]))
        result=h1.normalize(data,"metrics")
        self.assertIsNone(result[0][METRIC_HEADER[5]])
        self.assertEqual(result[0][METRIC_HEADER[6]],0)
        self.assertEqual(result[-1],["missing_numeric:"+METRIC_HEADER[5]])

    def test_unknown_metric_timezone_not_guessed(self):
        fields=METRIC_HEADER.copy()
        fields[0]="unknown timezone"
        self.assertFalse(h1.validate_schema(fields,"metrics"))

    def test_non_request_httperr_is_retained(self):
        values=dict(zip(HTTP_HEADER.split(),"2026-09-14 05:00:00 192.0.2.1 - - - Timer_ConnectionIdle".split()))
        result=h1.normalize(values,"httperr")
        self.assertIsNone(result[0]["sc-status"])
        self.assertIn("incomplete_http_request",result[-1])

    def test_invalid_numbers(self):
        for value in ("1,5","NaN","inf","-1"," 2"):
            with self.subTest(value=value),self.assertRaises(ValueError):
                h1.number(value)
        with self.assertRaises(ValueError):
            h1.number("2.5",integer=True)
        with self.assertRaises(ValueError):
            h1.number("101",maximum=100)

    def test_invalid_date_rejected(self):
        values=dict(zip(IIS_HEADER.split(),IIS_ROW.split()))
        values["date"]="2026-02-30"
        with self.assertRaisesRegex(ValueError,"invalid_timestamp"):
            h1.normalize(values,"iis")

    def test_quoted_csv_multiline_traceability(self):
        path=self.csv_file("tickets.csv",h1.TICKET_FIELDS,[["S-1","2026-09-14 00:00","Low","Synthetic","comma, and\nnewline","Open",""]])
        rows,_=self.parse(path,"tickets")
        self.assertEqual(rows[0][:2],(2,3))
        self.assertEqual(rows[0][3]["Descripcion"],"comma, and\nnewline")

    def test_bad_csv_cardinality(self):
        path=self.csv_file("short.csv",h1.TICKET_FIELDS,[["S-1","2026-09-14 00:00"]])
        self.assertEqual(self.parse(path,"tickets")[0][0][-1],"field_count")

    def test_bad_csv_quotes_abort(self):
        path=self.write("quotes.csv",",".join(h1.TICKET_FIELDS)+'\n"unclosed\n')
        with self.assertRaisesRegex(ValueError,"csv_syntax_abort"):
            self.parse(path,"tickets")

    def test_invalid_utf8_aborts(self):
        path=self.write("encoding.txt","")
        path.write_bytes(b"\xff")
        with self.assertRaises(UnicodeError):
            self.parse(path,"iis")

    def test_bom_and_blank_lines(self):
        path=self.write("bom.txt",f"\ufeff#Fields: {IIS_HEADER}\n\n{IIS_ROW}\n")
        rows,stat=self.parse(path,"iis")
        self.assertEqual(len(rows),1)
        self.assertEqual(stat["blank_lines"],1)
        self.assertEqual(rows[0][0],3)

    def make_kit(self):
        content=f"#Fields: {IIS_HEADER}\n{IIS_ROW}\n{IIS_ROW}\nBROKEN\n"
        self.write("kit/logs/iis/W3SVC2/a.log",content)
        self.write("kit/logs/iis/W3SVC2/a - copia.log",content)
        self.write("kit/logs/httperr/a.log",f"#Fields: {HTTP_HEADER}\n2026-09-14 05:00:00 192.0.2.1 GET /synthetic 200 Synthetic\n")
        self.csv_file("kit/eventos/e.csv",h1.EVENT_FIELDS,[["2026-09-14 00:00:00","System","Synthetic","1","Info","SYNTHETIC","fixture"]])
        self.csv_file("kit/metricas/m.csv",METRIC_HEADER,[["09/14/2026 00:00:00.000","1.0","2000","50","1000"," ","0"]])
        self.csv_file("kit/tickets/t.csv",h1.TICKET_FIELDS,[["S-1","2026-09-14 00:00","Low","Synthetic","fixture","Open",""]])
        self.write("kit/scripts/mantenimiento.log","Synthetic status\nSynthetic status\n")
        # Contents are intentionally not a BAT and must never be parsed.
        self.write("kit/scripts/mantenimiento_diario.bat","OUT_OF_SCOPE_FIXTURE")
        return self.root/"kit"

    def test_full_pipeline_reconciles_duplicates_retains_matches(self):
        kit=self.make_kit()
        before={p:h1.sha256(p) for p in kit.rglob("*") if p.is_file()}
        result=h1.run(kit,self.root/"out")
        self.assertEqual(result["totals"],dict(input_rows=12,accepted=8,rejected=1,duplicate_file_rows=3,in_week=6,outside_week=0,undated=2))
        self.assertEqual(result["quality"]["cross_source_candidates_retained"]["candidate_pairs"],2)
        self.assertIn({"source":"iis","groups":1,"extra_rows":1},result["quality"]["same_source_candidates_retained"])
        self.assertEqual(result["files"][1]["duplicate_of"],"logs/iis/W3SVC2/a.log")
        self.assertEqual(result["quality"]["quarantine"][0]["line_start"],4)
        self.assertEqual(before,{p:h1.sha256(p) for p in before})
        self.assertNotIn("OUT_OF_SCOPE_FIXTURE",json.dumps(result))
        # A second run replaces, never appends; public summary is byte-identical.
        first=(self.root/"out/summary.json").read_bytes()
        h1.run(kit,self.root/"out")
        self.assertEqual(first,(self.root/"out/summary.json").read_bytes())

    def test_protect_input_output_paths(self):
        kit=self.make_kit()
        with self.assertRaisesRegex(ValueError,"output_must"):
            h1.run(kit,kit/"derived")
        with self.assertRaisesRegex(ValueError,"output_must"):
            h1.run(kit,PROJECT/"evidencias/publicables")

    def test_missing_source_aborts(self):
        with self.assertRaisesRegex(ValueError,"missing_source"):
            h1.discover(self.root)

    def test_failed_run_removes_stale_summary(self):
        self.write("out/summary.json",'{"old":true}')
        with self.assertRaisesRegex(ValueError,"missing_source"):
            h1.run(self.root/"missing",self.root/"out")
        self.assertFalse((self.root/"out/summary.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
