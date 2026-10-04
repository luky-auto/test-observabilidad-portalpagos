"""Independent read-only checks and citation queries for the H1 output."""
import argparse
import hashlib
import json
import sqlite3
from pathlib import Path


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=Path("work-private/h1"))
    parser.add_argument("--input",type=Path,default=Path("input-private/kit_prueba_portalpagos"))
    parser.add_argument("--reference",type=Path)
    args=parser.parse_args()
    summary=json.loads((args.output/"summary.json").read_text(encoding="utf-8"))
    db=sqlite3.connect((args.output/"normalized.sqlite").resolve().as_uri()+"?mode=ro",uri=True)
    try:
        if db.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise ValueError("database_integrity")
        totals=summary["totals"]
        checks=[db.execute("SELECT count(*) FROM records").fetchone()[0]==totals["accepted"],
                db.execute("SELECT count(*) FROM issues").fetchone()[0]==totals["rejected"],
                totals["input_rows"]==totals["accepted"]+totals["rejected"]+totals["duplicate_file_rows"],
                totals["accepted"]==totals["in_week"]+totals["outside_week"]+totals["undated"]]
        for source in summary["files"]:
            path=(args.input/source["file"]).resolve()
            if not path.is_relative_to(args.input.resolve()):
                raise ValueError("unsafe_input_reference")
            with path.open("rb") as stream:
                checks.append(hashlib.file_digest(stream,"sha256").hexdigest()==source["sha256"])
            count=db.execute("SELECT count(*) FROM records WHERE file=?",(source["file"],)).fetchone()[0]
            checks.append(count==source["accepted"])
        if args.reference:
            checks.append((args.output/"summary.json").read_bytes()==args.reference.read_bytes())
        if not all(checks):
            raise ValueError("verification_failed")
        # Metadata only: no raw text, URLs, request parameters, IPs or event messages.
        query="""SELECT source,count(*) AS accepted,min(bogota) AS first_bogota,
                 max(bogota) AS last_bogota,sum(in_week) AS in_week
                 FROM records GROUP BY source ORDER BY source"""
        cursor=db.execute(query)
        print(json.dumps({"checks_passed":len(checks),"query":query,
              "sources":[dict(zip([c[0] for c in cursor.description],row)) for row in cursor]},indent=2))
    finally:
        db.close()


if __name__ == "__main__":
    main()
