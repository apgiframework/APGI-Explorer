"""The generated catalog is reproducible and covers every operation of the pinned contracts."""
import json
import unittest
from pathlib import Path

import generate_api_client as gen

ROOT = Path(__file__).resolve().parents[1]


class GenerationTests(unittest.TestCase):
    def test_generation_is_reproducible_and_checked_in(self):
        for target, text in gen.outputs().items():
            self.assertEqual(target.read_text(), text, f'regenerate {target.name}')

    def test_every_pinned_operation_is_in_the_catalog(self):
        spec = json.loads((ROOT / 'contracts/openapi-v1.json').read_text())
        ops = gen.operations(spec)
        raw = [(m, p) for p, item in spec['paths'].items() for m in item if m in gen.METHODS]
        self.assertEqual(len(ops), len(raw))
        self.assertEqual(len(ops), 121)
        source = gen.outputs()[ROOT / 'APGI-Explorer/Core/APIOperationCatalog+Generated.swift']
        for op in ops:
            self.assertIn(f'APIOperation(id: "{op["id"]}"', source)
        self.assertIn('static let operationCount = 121', source)

    def test_authentication_and_status_metadata(self):
        spec = json.loads((ROOT / 'contracts/openapi-v1.json').read_text())
        by_id = {o['id']: o for o in gen.operations(spec)}
        self.assertFalse(by_id['get_meta_v1_meta_get']['auth'])
        self.assertFalse(by_id['get_version_info_v1_version_get']['auth'], 'pinned spec lists /v1/version as public')
        self.assertEqual(sum(o['auth'] for o in by_id.values()), 102)
        self.assertEqual(by_id['refresh_token_v1_auth_refresh_post']['body'], 'required')
        self.assertTrue(all(o['ok'] for o in by_id.values()))

    def test_research_catalog_is_separate_from_the_deployed_contract(self):
        research = json.loads((ROOT / 'contracts/explorer-research-v1.json').read_text())
        deployed = json.loads((ROOT / 'contracts/openapi-v1.json').read_text())
        new_paths = set(research['paths']) - set(deployed['paths'])
        self.assertIn('/v1/explorer/config', new_paths)
        self.assertNotIn('/v1/explorer/config', deployed['paths'])

    def test_typed_schemas_cover_every_research_schema_property_and_operation(self):
        spec = json.loads((ROOT / 'contracts/explorer-research-v1.json').read_text())
        source = gen.outputs()[ROOT / 'APGI-Explorer/Core/ResearchSchemas+Generated.swift']
        for name, schema in spec['components']['schemas'].items():
            kind = 'enum' if 'enum' in schema else 'struct'
            self.assertIn(f'nonisolated {kind} {name}:', source)
            for prop in schema.get('properties', {}):
                self.assertIn(f'forKey: .{gen.camel(prop)})', source, f'{name}.{prop}')
        for op_id in (o['id'] for o in gen.operations(spec)):
            self.assertIn(f'TypedOperation<', source)
            self.assertIn(f'(operationID: "{op_id}")', source)
        self.assertEqual(source.count('static let ') - 1, len(gen.operations(spec)))  # + operationIDs

    def test_required_optional_and_default_semantics(self):
        spec = json.loads((ROOT / 'contracts/explorer-research-v1.json').read_text())
        source = gen.outputs()[ROOT / 'APGI-Explorer/Core/ResearchSchemas+Generated.swift']
        schemas = spec['components']['schemas']
        # Required keys decode strictly; defaulted keys fall back; absent optional keys become nil.
        self.assertIn('try container.decode(Bool.self, forKey: .researchEnabled)', source)
        self.assertIn('try container.decodeIfPresent(Bool.self, forKey: .productUse) ?? false', source)
        self.assertIn('let studyID: String?', source)
        self.assertIn('let ctx: [String: APIJSONValue]?', source)
        self.assertNotIn('researchEnabled: Bool?', source)
        self.assertEqual(schemas['ConsentStatusResponse']['properties']['product_use']['default'], False)

    def test_snake_case_names_follow_the_acronym_rule(self):
        self.assertEqual(gen.camel('participant_session_id'), 'participantSessionID')
        self.assertEqual(gen.camel('payload_sha256'), 'payloadSha256')
        self.assertEqual(gen.camel('consent_type', upper_first=True), 'ConsentType')

    def test_unsupported_shapes_fail_loudly(self):
        spec = {'openapi': '3.1.0', 'paths': {'/x': {'parameters': [{'name': 'a', 'in': 'query'}],
                'get': {'operationId': 'x', 'responses': {'200': {}}}}}}
        with self.assertRaises(AssertionError):
            gen.operations(spec)


if __name__ == '__main__':
    unittest.main()
