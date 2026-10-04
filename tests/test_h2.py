"""Synthetic unit tests: independent expectations for critical H2 calculations."""
import importlib.util
import unittest
from datetime import timedelta
from pathlib import Path

spec=importlib.util.spec_from_file_location('h2',Path(__file__).resolve().parents[1]/'reto1-diagnostico/h2_analyze.py')
h=importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


def row(time,status=200,latency=100,reason=None):
    return {'file':'synthetic','line_start':1,'line_end':1,'bogota':time,'status':status,
            'win32':0,'latency':latency,'reason':reason}


class H2Tests(unittest.TestCase):
    def test_utc_to_bogota_previous_day(self):
        self.assertEqual(h.local('2026-09-19T02:00:00+00:00').isoformat(),'2026-09-18T21:00:00-05:00')

    def test_naive_time_rejected(self):
        with self.assertRaises(ValueError):h.local('2026-09-18T12:00:00')

    def test_nearest_rank(self):
        self.assertEqual(h.percentile(list(range(1,21))),19)
        self.assertEqual(h.percentile([8]),8)
        self.assertEqual(h.percentile([None,3,9]),9)

    def test_empty_percentile_not_zero(self):
        self.assertIsNone(h.percentile([]))
        with self.assertRaises(ValueError):h.percentile([1],0)

    def test_error_classification(self):
        for status,win,expected in [(200,0,'http_success'),(304,0,'http_success'),(401,0,'client_error'),
                                     (503,0,'server_error'),(500,64,'server_error'),(200,64,'transport_error'),(None,0,'unknown')]:
            self.assertEqual(h.classify(status,win),expected)

    def test_ratio_denominator_and_missing_latency(self):
        s=h.stats([row(h.START.isoformat()),row(h.START.isoformat(),503,None)])
        self.assertEqual(s['http_success_pct'],50)
        self.assertEqual(s['latency_samples'],1)
        self.assertIsNone(h.stats([])['http_success_pct'])

    def test_windows_empty_is_unknown(self):
        w=h.windows([],h.START,h.START+timedelta(minutes=10))
        self.assertEqual([x['state'] for x in w],['unknown','unknown'])

    def test_half_open_boundaries(self):
        end=h.START+timedelta(minutes=10)
        rows=[row(h.START.isoformat()),row((h.START+timedelta(minutes=5)).isoformat(),503),row(end.isoformat())]
        w=h.windows(rows,h.START,end)
        self.assertEqual([x['requests'] for x in w],[1,1])
        self.assertEqual([x['state'] for x in w],['no_5xx_observed','failed'])

    def test_mixed_window_is_degraded(self):
        w=h.windows([row(h.START.isoformat()),row(h.START.isoformat(),500)],h.START,h.START+timedelta(minutes=5))
        self.assertEqual(w[0]['state'],'degraded')

    def test_sustained_transition_resets_after_gap(self):
        bins=[{'start':(h.START+timedelta(minutes=5*i)).isoformat(),'ok':v} for i,v in enumerate([True,True,False,True,True,True])]
        found=h.sustained(bins,lambda b:b['ok'])
        self.assertEqual(found['onset_window'],bins[3]['start'])
        self.assertEqual(found['confirmed_at'],(h.START+timedelta(minutes=30)).isoformat())

    def test_recovery_requires_observed_success(self):
        a=row('2026-09-18T14:38:00-05:00',503,None,'AppOffline')
        b=row('2026-09-18T15:03:59-05:00',503,None,'AppOffline')
        c=row('2026-09-18T15:04:00-05:00')
        self.assertEqual(h.offline_interval([a,b],[c])['bracket_seconds'],1560)
        self.assertIsNone(h.offline_interval([a,b],[])['first_api_success_after'])

    def test_linear_forecast_known_slope(self):
        r=h.regression([(0,100),(1,90),(2,80)])
        self.assertEqual(r['mb_per_hour'],-10)
        self.assertEqual(r['r_squared'],1)
        self.assertEqual(r['rmse_mb'],0)
        with self.assertRaises(ValueError):h.regression([(1,1)])


if __name__=='__main__':unittest.main(verbosity=2)
