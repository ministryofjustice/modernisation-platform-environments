import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('ops',Path(__file__).with_name('verify-operations.py'))
ops=importlib.util.module_from_spec(spec)
spec.loader.exec_module(ops)


class LifecycleChecks(unittest.TestCase):
    def test_global_enabled_one_day_rule(self):
        for filters in ({}, {'Prefix': ''}):
            self.assertTrue(ops.cleanup_rule_enabled([{'Status':'Enabled','Filter':filters,
                'AbortIncompleteMultipartUpload':{'DaysAfterInitiation':1}}]))

    def test_partial_disabled_missing_and_late_rules_do_not_pass(self):
        cases=[{'Status':'Disabled','Filter':{},'AbortIncompleteMultipartUpload':{'DaysAfterInitiation':1}},
               {'Status':'Enabled','Filter':{'Prefix':'someone-else/'},'AbortIncompleteMultipartUpload':{'DaysAfterInitiation':1}},
               {'Status':'Enabled','Filter':{},'AbortIncompleteMultipartUpload':{'DaysAfterInitiation':7}},
               {'Status':'Enabled','Filter':{}},
               {'Status':'Enabled','Filter':{'And':{'Tags':[{'Key':'test','Value':'yes'}]}},'AbortIncompleteMultipartUpload':{'DaysAfterInitiation':1}}]
        for rule in cases:
            with self.subTest(rule=rule):self.assertFalse(ops.cleanup_rule_enabled([rule]))


if __name__=='__main__':unittest.main()
