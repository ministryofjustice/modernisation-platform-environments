import importlib.util
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import Mock


def _install_stub_modules():
    boto3_module = types.ModuleType("boto3")

    class _StubClient:
        def __init__(self, service_name):
            self.service_name = service_name

    boto3_module.client = lambda service_name, **kwargs: _StubClient(service_name)
    sys.modules["boto3"] = boto3_module

    aws_xray_core_module = types.ModuleType("aws_xray_sdk.core")
    aws_xray_core_module.patch_all = lambda: None
    aws_xray_core_module.xray_recorder = Mock()
    sys.modules["aws_xray_sdk.core"] = aws_xray_core_module

    dotenv_module = types.ModuleType("dotenv")
    dotenv_module.load_dotenv = lambda: None
    sys.modules["dotenv"] = dotenv_module

    oracledb_module = types.ModuleType("oracledb")
    oracledb_module.version = ""
    sys.modules["oracledb"] = oracledb_module

    sqlalchemy_module = types.ModuleType("sqlalchemy")
    sqlalchemy_module.create_engine = lambda *args, **kwargs: Mock(name="engine")
    sys.modules["sqlalchemy"] = sqlalchemy_module

    sqlalchemy_exc_module = types.ModuleType("sqlalchemy.exc")

    class NoSuchTableError(Exception):
        pass

    sqlalchemy_exc_module.NoSuchTableError = NoSuchTableError
    sys.modules["sqlalchemy.exc"] = sqlalchemy_exc_module

    mojap_metadata_module = types.ModuleType("mojap_metadata")

    class Metadata:
        pass

    mojap_metadata_module.Metadata = Metadata
    sys.modules["mojap_metadata"] = mojap_metadata_module

    converters_pkg = types.ModuleType("mojap_metadata.converters")
    sys.modules["mojap_metadata.converters"] = converters_pkg

    etl_manager_converter_module = types.ModuleType("mojap_metadata.converters.etl_manager_converter")
    etl_manager_converter_module.EtlManagerConverter = type("EtlManagerConverter", (), {})
    sys.modules["mojap_metadata.converters.etl_manager_converter"] = etl_manager_converter_module

    glue_converter_module = types.ModuleType("mojap_metadata.converters.glue_converter")
    glue_converter_module.GlueConverter = type("GlueConverter", (), {})
    sys.modules["mojap_metadata.converters.glue_converter"] = glue_converter_module

    sqlalchemy_converter_module = types.ModuleType("mojap_metadata.converters.sqlalchemy_converter")
    sqlalchemy_converter_module.SQLAlchemyConverter = type("SQLAlchemyConverter", (), {})
    sys.modules["mojap_metadata.converters.sqlalchemy_converter"] = sqlalchemy_converter_module


def _load_module():
    _install_stub_modules()
    module_path = Path(__file__).parent / "main.py"
    spec = importlib.util.spec_from_file_location("metadata_generator_main", module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TestMetadataExtractor(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module = _load_module()
        cls.MetadataExtractor = cls.module.MetadataExtractor
        cls.NoSuchTableError = cls.module.NoSuchTableError

    def _build_extractor(self, objects):
        extractor = self.MetadataExtractor.__new__(self.MetadataExtractor)
        extractor.objects = objects
        extractor.schema_name = "claims"
        extractor.missing_objects = []
        extractor._write_database_objects = Mock()
        return extractor

    def test_get_database_metadata_when_all_tables_exist(self):
        extractor = self._build_extractor(["claims.a", "claims.b"])
        table_a = object()
        table_b = object()
        extractor.get_table_metadata = Mock(side_effect=[table_a, table_b])

        tables = extractor.get_database_metadata("metadata-bucket")

        self.assertEqual(tables, [table_a, table_b])
        self.assertEqual(extractor.missing_objects, [])
        extractor._write_database_objects.assert_called_once_with("metadata-bucket")

    def test_get_database_metadata_continues_after_missing_table(self):
        extractor = self._build_extractor(["claims.missing_table", "claims.valid_table"])
        valid_table = object()
        extractor.get_table_metadata = Mock(
            side_effect=[self.NoSuchTableError("claims.missing_table"), valid_table]
        )

        with self.assertLogs(self.module.logger, level="ERROR") as captured_logs:
            tables = extractor.get_database_metadata("metadata-bucket")

        self.assertEqual(tables, [valid_table])
        self.assertEqual(extractor.missing_objects, ["claims.missing_table"])
        self.assertEqual(extractor.get_table_metadata.call_count, 2)
        self.assertIn(
            "Could not reflect configured database object: claims.missing_table",
            "\n".join(captured_logs.output),
        )

    def test_get_database_metadata_reports_multiple_missing_tables(self):
        extractor = self._build_extractor(["claims.first_missing", "claims.second_missing", "claims.valid"])
        valid_table = object()
        extractor.get_table_metadata = Mock(
            side_effect=[
                self.NoSuchTableError("claims.first_missing"),
                self.NoSuchTableError("claims.second_missing"),
                valid_table,
            ]
        )

        tables = extractor.get_database_metadata("metadata-bucket")

        self.assertEqual(tables, [valid_table])
        self.assertEqual(
            extractor.missing_objects,
            ["claims.first_missing", "claims.second_missing"],
        )

    def test_raise_for_missing_objects_raises_combined_error(self):
        extractor = self._build_extractor(["claims.a"])
        extractor.missing_objects = ["claims.second_missing", "claims.first_missing"]

        with self.assertRaises(self.NoSuchTableError) as raised_error:
            extractor.raise_for_missing_objects()

        self.assertEqual(
            str(raised_error.exception),
            "Failed to reflect configured database object(s): claims.first_missing, claims.second_missing",
        )

    def test_get_database_metadata_does_not_swallow_unexpected_exception(self):
        extractor = self._build_extractor(["claims.bad_table", "claims.never_reached"])
        extractor.get_table_metadata = Mock(side_effect=RuntimeError("boom"))

        with self.assertRaises(RuntimeError):
            extractor.get_database_metadata("metadata-bucket")

        extractor._write_database_objects.assert_not_called()


if __name__ == "__main__":
    unittest.main()
