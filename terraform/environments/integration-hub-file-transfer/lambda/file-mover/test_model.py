import unittest

from mft_file_mover.model import plan_multipart_copy, select_route


class MultipartCopyPlanTest(unittest.TestCase):
    def test_one_byte_object_uses_one_multipart_part(self):
        self.assertEqual(
            plan_multipart_copy(1, 1024**3, 1000)[0].range_end,
            0,
        )

    def test_zero_byte_object_does_not_use_multipart_copy(self):
        with self.assertRaisesRegex(ValueError, "positive object size"):
            plan_multipart_copy(0, 1024**3, 1000)

    def test_part_ranges_cover_the_exact_object_size(self):
        parts = plan_multipart_copy(25, 10, 1000)

        self.assertEqual(
            [(part.part_number, part.range_start, part.range_end, part.size) for part in parts],
            [(1, 0, 9, 10), (2, 10, 19, 10), (3, 20, 24, 5)],
        )

    def test_rejects_an_object_over_the_configured_part_limit(self):
        with self.assertRaisesRegex(ValueError, "requires 1001 parts"):
            plan_multipart_copy((1000 * 1024**3) + 1, 1024**3, 1000)


class RouteSelectionTest(unittest.TestCase):
    def test_selects_clean_for_a_clean_event_result(self):
        self.assertEqual(select_route("NO_THREATS_FOUND", True), "clean")

    def test_selects_quarantine_for_a_threat_event_result(self):
        self.assertEqual(select_route("THREATS_FOUND", True), "quarantine")

    def test_selects_investigation_for_non_terminal_routes(self):
        for status in ["UNSUPPORTED", "ACCESS_DENIED", "FAILED"]:
            with self.subTest(status=status):
                self.assertEqual(select_route(status, True), "investigation")

    def test_selects_investigation_when_the_scan_result_does_not_match_the_tag(self):
        for status in ["NO_THREATS_FOUND", "THREATS_FOUND"]:
            with self.subTest(status=status):
                self.assertEqual(select_route(status, False), "investigation")


if __name__ == "__main__":
    unittest.main()