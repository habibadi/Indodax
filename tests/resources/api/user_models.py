from dataclasses import dataclass
from typing import Any, Dict, List


@dataclass
class ApiError(Exception):
    message: str
    code: str | None = None


def ensure_success(response: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(response, dict):
        raise ValueError("Response must be a dict")
    success = response.get("success")
    if success != 1:
        message = response.get("error", "Unknown error")
        code = response.get("error_code")
        raise ApiError(message=message, code=code)
    data = response.get("return")
    if not isinstance(data, dict):
        raise ValueError("Field 'return' must be a dict")
    return data


def validate_get_info_response(response: Dict[str, Any]) -> Dict[str, Any]:
    data = ensure_success(response)
    balance = data.get("balance")
    if not isinstance(balance, dict):
        raise ValueError("Field 'balance' must be a dict")
    wallet = data.get("wallet")
    if wallet is not None and not isinstance(wallet, dict):
        raise ValueError("Field 'wallet' must be a dict when present")
    username = data.get("username")
    if username is not None and not isinstance(username, str):
        data["username"] = str(username)
    server_time = data.get("server_time")
    if not isinstance(server_time, int):
        raise ValueError("Field 'server_time' must be an int")
    return data


def validate_trade_response(response: Dict[str, Any]) -> Dict[str, Any]:
    data = ensure_success(response)
    order_id = data.get("order_id")
    if not isinstance(order_id, int):
        raise ValueError("Field 'order_id' must be an int")
    return data


def validate_trade_history_response(response: Dict[str, Any]) -> List[Dict[str, Any]]:
    data = ensure_success(response)
    trades = data.get("trades")
    if not isinstance(trades, list):
        raise ValueError("Field 'trades' must be a list")
    for t in trades:
        if not isinstance(t, dict):
            raise ValueError("Each trade must be a dict")
        trade_id = t.get("trade_id")
        if trade_id is not None and not isinstance(trade_id, int):
            raise ValueError("Field 'trade_id' must be an int when present")
        trade_type = t.get("type")
        if trade_type is not None and trade_type not in ("buy", "sell"):
            raise ValueError("Field 'type' must be 'buy' or 'sell' when present")
        price = t.get("price")
        amount = t.get("amount")
        if price is not None and not isinstance(price, (int, float, str)):
            raise ValueError("Field 'price' must be number or string when present")
        if amount is not None and not isinstance(amount, (int, float, str)):
            raise ValueError("Field 'amount' must be number or string when present")
    return trades


def validate_open_orders_response(response: Dict[str, Any]) -> Dict[str, Any]:
    data = ensure_success(response)
    orders = data.get("orders")
    if orders is not None and not isinstance(orders, list):
        raise ValueError("Field 'orders' must be a list when present")
    return data


def validate_order_history_response(response: Dict[str, Any]) -> List[Dict[str, Any]]:
    data = ensure_success(response)
    history = data.get("orders")
    if not isinstance(history, list):
        raise ValueError("Field 'orders' must be a list")
    for o in history:
        if not isinstance(o, dict):
            raise ValueError("Each order must be a dict")
        order_id = o.get("order_id")
        if order_id is not None and not isinstance(order_id, int):
            raise ValueError("Field 'order_id' must be an int when present")
    return history


def validate_get_order_response(response: Dict[str, Any]) -> Dict[str, Any]:
    data = ensure_success(response)
    order = data.get("order")
    if not isinstance(order, dict):
        raise ValueError("Field 'order' must be a dict")
    return order


def validate_cancel_order_response(response: Dict[str, Any]) -> Dict[str, Any]:
    data = ensure_success(response)
    cancelled = data.get("order_id")
    if cancelled is None:
        raise ValueError("Field 'order_id' is required")
    return data
