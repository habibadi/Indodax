from locust import HttpUser, task, between, events
import json
import time


class DummyApiUser(HttpUser):
    """
    Simulasi user yang memanggil dummy.restapiexample.com.

    Target beban: ~10 RPS (Requests Per Second) dengan kombinasi
    beberapa endpoint GET dan satu endpoint POST.
    """

    # Default wait time; akan dioverride dari CLI lewat events.init_command_line_parser
    wait_time = between(0.1, 0.3)

    @task(4)
    def get_all_employees(self):
        """GET /api/v1/employees"""
        with self.client.get("/api/v1/employees", name="GET /employees", catch_response=True) as response:
            self._assert_ok_json(response)

    @task(2)
    def get_single_employee(self):
        """GET /api/v1/employee/1"""
        with self.client.get("/api/v1/employee/1", name="GET /employee/{id}", catch_response=True) as response:
            self._assert_ok_json(response)

    @task(1)
    def create_employee(self):
        """POST /api/v1/create"""
        payload = {
            "name": f"locust-user-{int(time.time())}",
            "salary": "123",
            "age": "23",
        }
        headers = {"Content-Type": "application/json"}
        with self.client.post("/api/v1/create", name="POST /create", json=payload, headers=headers, catch_response=True) as response:
            self._assert_ok_json(response)

    def _assert_ok_json(self, response):
        """
        Assertion dasar untuk setiap request:
        - HTTP status code 200
        - Response dapat di-parse sebagai JSON
        """
        if response.status_code != 200:
            response.failure(f"Unexpected status code: {response.status_code}")
            return

        try:
            data = response.json()
        except json.JSONDecodeError:
            response.failure("Response is not valid JSON")
            return

        # Tambahan: banyak endpoint dummy ini mengembalikan key 'status'
        # dengan nilai 'success' ketika OK. Jika tidak ada, tidak dianggap gagal,
        # hanya diberi info di log.
        status = data.get("status")
        if status not in (None, "success"):
            response.failure(f"Unexpected logical status in payload: {status}")


# ---------- Custom Listener & Summary ----------

_REQUEST_STATS = {
    "total_requests": 0,
    "total_failures": 0,
    "total_response_time_ms": 0.0,
}


@events.init_command_line_parser.add_listener
def on_init_command_line_parser(parser):
    """
    Menambahkan opsi CLI kustom:
    --target-rps : target RPS untuk evaluasi hasil
    --wait-min   : minimum wait time antar request
    --wait-max   : maksimum wait time antar request
    """
    parser.add_argument(
        "--target-rps",
        type=float,
        default=10.0,
        help="Target average RPS untuk dianggap OK (default: 10.0).",
    )
    parser.add_argument(
        "--wait-min",
        type=float,
        default=0.1,
        help="Minimum wait time antar task dalam detik (default: 0.1).",
    )
    parser.add_argument(
        "--wait-max",
        type=float,
        default=0.3,
        help="Maksimum wait time antar task dalam detik (default: 0.3).",
    )


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """
    Mengaplikasikan konfigurasi wait time dari CLI ke DummyApiUser.
    """
    wait_min = environment.parsed_options.wait_min
    wait_max = environment.parsed_options.wait_max
    DummyApiUser.wait_time = between(wait_min, wait_max)


@events.request.add_listener
def on_request(request_type, name, response_time, response_length, response, context, exception, **kwargs):
    """
    Listener untuk setiap request:
    - Mengumpulkan total request, failure, dan total response time.
    - Gagal dihitung jika ada exception atau response.failure dipanggil.
    """
    _REQUEST_STATS["total_requests"] += 1
    _REQUEST_STATS["total_response_time_ms"] += float(response_time)

    if exception is not None or (response is not None and getattr(response, "failure", None) and response.failure):
        _REQUEST_STATS["total_failures"] += 1


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """
    Listener saat test selesai:
    - Menghitung RPS rata-rata.
    - Menghitung average response time.
    - Menampilkan ringkasan singkat di stdout.
    """
    stats_total = environment.runner.stats.total
    if stats_total.start_time and stats_total.last_request_timestamp:
        run_time = stats_total.last_request_timestamp - stats_total.start_time
    else:
        run_time = 0.0
    total = _REQUEST_STATS["total_requests"]
    failures = _REQUEST_STATS["total_failures"]
    total_rt = _REQUEST_STATS["total_response_time_ms"]

    avg_rps = (total / run_time) if run_time > 0 else 0.0
    avg_rt = (total_rt / total) if total > 0 else 0.0
    failure_rate = (failures / total * 100.0) if total > 0 else 0.0

    print("\n=== Dummy REST API Load Test Summary ===")
    print(f"Total requests      : {total}")
    print(f"Total failures      : {failures} ({failure_rate:.2f}%)")
    print(f"Average RPS         : {avg_rps:.2f}")
    print(f"Average resp time   : {avg_rt:.2f} ms")

    target_rps = getattr(environment.parsed_options, "target_rps", 10.0)

    # Interpretasi dasar terhadap target RPS dari CLI
    if avg_rps >= target_rps and failure_rate < 1.0:
        print(f"Result              : OK – Target >= {target_rps:.2f} RPS tercapai dengan error rate < 1%.")
    else:
        print(f"Result              : ATTENTION – Target {target_rps:.2f} RPS belum konsisten tercapai atau error rate tinggi.")
