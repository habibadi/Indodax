import os
import yaml


def _get_tests_dir():
    current = os.path.abspath(__file__)
    return os.path.dirname(os.path.dirname(current))


def load_trading_flows():
    tests_dir = _get_tests_dir()
    data_path = os.path.join(tests_dir, "data", "api", "trading_flows.yaml")
    with open(data_path, "r", encoding="utf-8") as f:
        content = yaml.safe_load(f) or {}
    tests = content.get("tests", [])
    if not isinstance(tests, list):
        raise ValueError("Field 'tests' in trading_flows.yaml must be a list")
    return tests


def get_trading_flow_by_id(test_id):
    tests = load_trading_flows()
    for item in tests:
        if not isinstance(item, dict):
            continue
        if str(item.get("id")) == str(test_id):
            return item
    raise ValueError(f"Trading flow with id '{test_id}' not found")


def load_market_usdtidr_tests():
    tests_dir = _get_tests_dir()
    data_path = os.path.join(tests_dir, "data", "web", "market_usdtidr.yaml")
    with open(data_path, "r", encoding="utf-8") as f:
        content = yaml.safe_load(f) or {}
    tests = content.get("tests", [])
    if not isinstance(tests, list):
        raise ValueError("Field 'tests' in market_usdtidr.yaml must be a list")
    return tests


def get_market_usdtidr_test_by_id(test_id):
    tests = load_market_usdtidr_tests()
    for item in tests:
        if not isinstance(item, dict):
            continue
        if str(item.get("id")) == str(test_id):
            return item
    raise ValueError(f"USDTIDR UI test with id '{test_id}' not found")
