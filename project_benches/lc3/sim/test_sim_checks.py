"""Regression tests for simulator transcript validation."""

import unittest

from sim_checks import read_sim_summary


class TestSimSummary(unittest.TestCase):

    def setUp(self):
        self.clean = (
            "# UVM_ERROR : 0\n"
            "# UVM_FATAL : 0\n"
            "# Errors: 0, Warnings: 123\n"
        )

    def test_clean_summary(self):
        self.assertEqual(read_sim_summary(self.clean), (0, 0))

    def test_reported_uvm_error(self):
        log = "# UVM_ERROR example\n" + self.clean.replace(
            "UVM_ERROR : 0", "UVM_ERROR : 1"
        )
        self.assertEqual(read_sim_summary(log), (1, 0))

    def test_missing_summary(self):
        with self.assertRaises(ValueError):
            read_sim_summary(self.clean.split("# Errors:")[0])

    def test_simulator_error(self):
        with self.assertRaises(ValueError):
            read_sim_summary(
                self.clean.replace("Errors: 0", "Errors: 1")
            )

    def test_suppressed_error(self):
        with self.assertRaises(ValueError):
            read_sim_summary(self.clean.replace(
                "Warnings: 123",
                "Warnings: 123, Suppressed Errors: 1"
            ))

    def test_inconsistent_uvm_count(self):
        with self.assertRaises(ValueError):
            read_sim_summary(self.clean.replace(
                "UVM_ERROR : 0", "UVM_ERROR : 1"
            ))


if __name__ == "__main__":
    unittest.main()
