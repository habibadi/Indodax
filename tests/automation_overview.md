## Automation Overview

Dokumen ini merangkum desain dan struktur automation di repository ini untuk:

- Endpoint Automation (API trading flow)
- UI Automation Web (market page & trading flow USDT/IDR)
- UI Automation Mobile (mirror trading flow Web, Android/iOS)
- Strategi penandaan (tagging) lintas platform

---

## 1. Endpoint Automation (API)

### Tujuan

- Meng-automate trading flow API Indodax end-to-end.
- Menjaga struktur bersih dan mudah di-maintain:
  - Test suite di `tests/suites`.
  - Resource/keywords di `tests/resources`.
  - Library Python di `tests/libraries`.
  - Test data (YAML) untuk data-driven testing.
- Menyediakan mekanisme logging ke Discord + pengiriman artifacts (log HTML).

### Struktur Utama

- **Suite utama trading flow**  
  `tests/suites/api/trading_flow.robot`
  - 9 test case: `TC_FLOW_01` s/d `TC_FLOW_09`.
  - Menggunakan:
    - Resource API + Discord logging:  
      `tests/resources/api/auth_keywords.resource`
    - Library Python untuk validasi response:  
      `tests/resources/api/user_models.py`
    - Data loader YAML:  
      `tests/libraries/test_data_loader.py`
    - Test data trading flow (YAML):  
      `tests/data/api/trading_flows.yaml`

- **Environment setup**  
  `tests/resources/common/env_setup.resource`
  - Keyword `Load Environment`:
    - Load config environment (`public_base_url`, `trade_base_url`, `api_key`, `api_secret`).
    - Set sebagai suite variables.

- **Account repository**  
  `tests/libraries/account_repository.py`
  - Mengambil dan mendekripsi `api_key` dan `api_secret` dari DB `test_accounts`
    menggunakan master key environment `INDODAX_TEST_MASTER_KEY_DEV`.

### Layering & Responsibility

1. **Test Suite (`trading_flow.robot`)**
   - Fokus pada business flow dan assertion:
     - Mengambil data flow dari YAML (`Get Trading Flow By Id`) berdasarkan `tc_id` (`TC-01` s/d `TC-09`).
     - Menggunakan label account dari test data.
     - Memanggil keyword high-level untuk API:
       - `Get Info From Account`
       - `Call Indodax Private Method From Account` (trade, openOrders, tradeHistory, dst).
     - Assertion jelas:
       - Balance sebelum/sesudah.
       - Status order (filled / partial).
       - Pesan error dan `error_code` untuk negative case.
     - Logging hasil ke Discord via `Log Trading Flow Result` di akhir setiap test case.

2. **API Keywords & Discord Logging (`auth_keywords.resource`)**

   - **Lapisan API:**
     - Membungkus library Python dan environment:
       - `Create Indodax Public Session`
       - `Create Indodax Private Session Data`
       - `Create Indodax Private Session Data From Account`
       - `Call Indodax Private Method`
       - `Call Indodax Private Method From Account`
       - Helper seperti `Get Info From Account`,
         `Cancel All Open Orders For Pair And Account`,
         `Ensure IDR Balance At Least`, `Ensure BTC Balance At Least`.

   - **Logging ke Discord:**
     - `Send Trading Flow Discord Log`
       - Mengirim POST ke Discord webhook dengan payload JSON `{ "content": "<message>" }`.
     - `Initialize Trading Flow Logging`
       - Inisialisasi list suite `TRADING_FLOW_RESULTS`.
     - `Log Trading Flow Result`
       - Membentuk entry dict hasil TC `{tc_id, env, pair, type, order_type, amount, status}`.
       - Menyimpan entry ke list `TRADING_FLOW_RESULTS`.
       - Logging JSON ke `log.html` untuk debugging.
     - `Send Trading Flow Suite Summary`
       - Mengambil semua entry `TRADING_FLOW_RESULTS`.
       - Membuat rangkuman multi-line:
         - `- TC-01 | btc_idr | buy/market | amount=... | status=passed`
       - Mengirim satu pesan text summary ke Discord.
     - `Send Trading Flow Artifacts`
       - Meng-upload `log.html` sebagai attachment ke Discord webhook.
     - `Finalize Trading Flow Reporting`
       - Dipanggil di Suite Teardown trading flow:
         - Memanggil `Send Trading Flow Suite Summary`.
         - Memanggil `Send Trading Flow Artifacts`.

3. **Python Libraries**

   - `tests/libraries/api_client.py`
     - Membangun payload dan signature HMAC SHA-512.
     - `call_private_method` mengeksekusi HTTP POST ke `TRADE_BASE_URL`
       dengan header `Key` dan `Sign`.
   - `tests/resources/api/user_models.py`
     - Fungsi `ensure_success` dan berbagai `validate_*_response`
       untuk memvalidasi struktur JSON response dan melempar `ApiError`
       ketika respons tidak sesuai ekspektasi.

### Strategi Tagging API

- Setiap test case di `trading_flow.robot` diberi tag yang konsisten:
  - Platform: `api`
  - Domain: `flow`, `trade`
  - Kategori order / skenario:
    - `market`, `limit`, `stop_limit`, `order_management`, `negative`, `regulatory`, `compliance`, `validation`
  - Mode: `pro` atau `lite`
  - Prioritas: `P0`, `P1`, `P2`
  - ID test bisnis: `TC-xx`
- Contoh:
  - `TC_FLOW_01_...` → `[Tags]    api    flow    trade    market    pro    P0    TC-01`
  - `TC_FLOW_08_...` → `[Tags]    api    flow    trade    order_management    pro    P1    TC-08`

### Mode Eksekusi

- **Run nyata (end-to-end)**

  ```bash
  robot --variable ENV:dev \
        --variable SIMULATE_ONLY:False \
        --variable "DISCORD_WEBHOOK_TRADING_FLOW:<<WEBHOOK_URL>>" \
        tests/suites/api/trading_flow.robot
  ```

  - Menyentuh API Indodax dan akun test.
  - Mengirim hasil per test + summary suite + `log.html` ke Discord.

- **Mode simulasi + Discord (tanpa menyentuh API/akun)**

  ```bash
  robot --variable ENV:dev \
        --variable SIMULATE_ONLY:True \
        --variable "DISCORD_WEBHOOK_TRADING_FLOW:<<WEBHOOK_URL>>" \
        tests/suites/api/trading_flow.robot
  ```

  - Flow bisnis dieksekusi sampai level data (YAML), tapi call ke API/akun
    dibypass, hanya logging ke Discord.

- **Robot `--dryrun`**
  - Hanya memvalidasi struktur test; tidak menjalankan keyword dan tidak
    mengirim apa pun ke Discord.

---

## 2. UI Automation (Web)

### Tujuan

- Meng-automate UI halaman market Indodax, dimulai dari:
  - `https://indodax.com/market/USDTIDR`
  - Trading flow dasar USDT/IDR yang paralel dengan API (`TC-01` s/d `TC-08`).
- Menggunakan Robot Framework + Browser (Playwright) dengan:
  - Page Object / screen abstraction.
  - Locator strategy yang maintainable.
  - Layering: test → page/screen → browser/keyword infra.

### Struktur Utama

- **Test suite web**
  - `tests/suites/web/market_usdtidr_web.robot`  
    (saat ini diimplementasikan di `market_usdtidr.robot` dan dapat di-rename sesuai konvensi ini)

- **Resource browser (infra UI)**
  - `tests/resources/web/browser_keywords.resource`

- **Page object halaman market**
  - `tests/resources/web/pages/market_page.resource`

- **Test data trading flow USDT/IDR (YAML)**
  - `tests/data/web/market_usdtidr.yaml`

### Layer Browser / Infra

- File: `tests/resources/web/browser_keywords.resource`
  - Menggunakan `Library    Browser`.
  - Variabel:
    - `${BASE_URL} = https://indodax.com`
    - `${HEADLESS} = True`
  - Keyword:
    - `Open Browser For Web Tests`
      - `New Browser    chromium    headless=${HEADLESS}`
      - `New Context`, `New Page    about:blank`
    - `Close Browser For Web Tests`
      - `Close Browser`
    - `Go To Market Page`
      - Menerima path (`/market/USDTIDR`) dan navigasi ke `${BASE_URL}${path}`.

### Page Object: Halaman Market USDTIDR

- File: `tests/resources/web/pages/market_page.resource`
  - Meng-`Resource` `browser_keywords.resource`.
  - Menyediakan keyword level halaman untuk:
    - Membuka halaman market USDT/IDR dan beralih ke Mode Pro.
    - Memilih tab Market/Limit/Stop-Limit (Beli/Jual).
    - Mengisi harga, jumlah, dan slider persentase.
    - Submit order dan navigasi ke halaman History → tab Open Order.
  - Terdapat keyword eksekutor per test case, misalnya:
    - `Execute USDTIDR TC01 Market Buy 100 Percent`
    - `Execute USDTIDR TC02 Market Sell Specified Quantity`
    - `Execute USDTIDR TC03 Limit Buy Filled`
    - `Execute USDTIDR TC04 Limit Sell Partial Execution`
    - `Execute USDTIDR TC05 Stop Limit Sell Order`
    - `Execute USDTIDR TC06 Stop Limit Buy Order`
    - `Execute USDTIDR TC07 Below Minimum Transaction Limit`
    - `Execute USDTIDR TC08 Cancel Limit Buy To Release Frozen Funds`
  - Masing-masing keyword ini merealisasikan langkah bisnis yang didefinisikan
    di test data YAML `market_usdtidr.yaml`.

### Test Suite: Data-Driven & Assertion

- File: `tests/suites/web/market_usdtidr.robot`

  - Meng-`Resource`:
    - `../../resources/web/browser_keywords.resource`
    - `../../resources/web/pages/market_page.resource`
  - Suite Setup / Teardown:
    - `Suite Setup    Open Browser For Web Tests`
    - `Suite Teardown    Close Browser For Web Tests`
  - Menggunakan `Test Template    USDTIDR Market Smoke`.
  - Variabel:

    ```robot
    ${ENV}    dev
    ```

  - Data test di-load dari:

    ```yaml
    tests/data/web/market_usdtidr.yaml
    ```

  - Tiap test case di section `*** Test Cases ***` memetakan:
    - Nama test bisnis (mis. `TC-01 Trader Executes Market Buy Order using Total Available Balance`)
    - Tag yang selaras dengan API (lihat bagian Tagging).
    - `TC-xx` yang akan diteruskan ke template.

  - Keyword template:

    ```robot
    USDTIDR Market Smoke
        [Arguments]    ${tc_id}    ${env}
        ${scenario}=    Get Market Usdtidr Test By Id    ${tc_id}
        # Routing ke eksekutor per TC:
        # Run Keyword If    '${tc_id}' == 'TC-01'    Execute USDTIDR TC01 Market Buy 100 Percent    ${env}    ${scenario}
        # ...
    ```

  - Dengan pola ini:
    - Behavior bisnis didefinisikan di YAML.
    - Suite hanya bertugas mapping TC → eksekutor page object.
    - Penambahan test baru cukup:
      - Tambah entry YAML.
      - Tambah baris di `*** Test Cases ***`.
      - Tambah satu baris routing di keyword template.

### Data-Driven Trading Flow USDT/IDR (Web)

- File data: `tests/data/web/market_usdtidr.yaml`
- Berisi kumpulan skenario `tests:` dengan `id` `TC-01` s/d `TC-08`:
  - `TC-01` – Market Buy 100% saldo IDR
  - `TC-02` – Market Sell jumlah USDT tertentu
  - `TC-03` – Limit Buy yang masuk ke saldo terbeku
  - `TC-04` – Limit Sell dengan partial fill lalu cancel
  - `TC-05` – Stop-Limit Sell untuk mitigasi loss
  - `TC-06` – Stop-Limit Buy untuk breakout
  - `TC-07` – Validasi minimum nominal transaksi (negative case)
  - `TC-08` – Cancel Limit Buy untuk melepaskan saldo IDR terbeku

### Strategi Tagging Web

- Setiap test case di `market_usdtidr_web.robot` diberi tag yang paralel dengan API:
  - Platform: `web`
  - Domain: `flow`, `trade`
  - Kategori order / skenario:
    - `market`, `limit`, `stop_limit`, `order_management`, `negative`, `validation`
  - Mode: `pro` (atau `lite` jika relevan)
  - Prioritas: `P0`, `P1`, `P2`
  - ID test bisnis: `TC-xx`
- Contoh:
  - TC-01 Web: `[Tags]    web    flow    trade    market    pro    P0    TC-01`
  - TC-08 Web: `[Tags]    web    flow    trade    order_management    pro    P1    TC-08`

### Cara Menjalankan UI Tests

1. Install library Browser (sekali):

   ```bash
   pip install -U robotframework-browser
   ```

2. Inisialisasi Playwright dan browser dependencies (sekali):

   ```bash
   rfbrowser init
   ```

3. Jalankan test:

   ```bash
   robot tests/suites/web/market_usdtidr.robot
   ```

4. Untuk cek struktur saja (tanpa membuka browser):

   ```bash
   robot --dryrun tests/suites/web/market_usdtidr.robot
   ```

---

## 3. UI Automation (Mobile)

### Tujuan

- Menyediakan lapisan test Mobile yang:
  - Menggunakan test data dan flow bisnis yang sama dengan Web (`TC-01` s/d `TC-08`).
  - Pada tahap awal masih memanfaatkan Browser (mobile web) dan page object yang sama,
    sebelum dievolusi ke Appium/native (Android/iOS).

### Struktur Utama

- **Test suite mobile (mirror Web)**
  - `tests/suites/mobile/market_usdtidr_mobile.robot`  
    (saat ini diimplementasikan di `checkout_mobile.robot` dan dapat di-rename sesuai konvensi ini)

- **Infra & page object yang digunakan kembali**
  - `tests/resources/web/browser_keywords.resource`
  - `tests/resources/web/pages/market_page.resource`
  - `tests/libraries/test_data_loader.py`
  - `tests/data/web/market_usdtidr.yaml`

### Pola Eksekusi

- Suite mobile menggunakan `Test Template    USDTIDR Mobile Market Smoke` yang:
  - Menerima `tc_id` (`TC-01` s/d `TC-08`) dan `env`.
  - Memanggil `Get Market Usdtidr Test By Id` untuk membaca YAML.
  - Mendelegasikan ke keyword eksekutor yang sama seperti Web:
    - `Execute USDTIDR TC01 Market Buy 100 Percent`
    - `Execute USDTIDR TC02 Market Sell Specified Quantity`
    - ...
    - `Execute USDTIDR TC08 Cancel Limit Buy To Release Frozen Funds`
- Dengan desain ini:
  - Flow bisnis, data, dan assertion tetap konsisten lintas Web/Mobile.
  - Perbedaan platform nantinya cukup diisolasi di layer locators/engine,
    tanpa mengubah suite dan data.

### Strategi Tagging Mobile

- Setiap test case mobile diberi tag paralel dengan API & Web:
  - Platform: `mobile`
  - Domain: `flow`, `trade`
  - Kategori order / skenario: sama seperti Web/API (`market`, `limit`, `stop_limit`, dll.).
  - Mode: `pro`
  - Prioritas: `P0`, `P1`, `P2`
  - ID test bisnis: `TC-xx`
- Contoh:
  - TCM-01: `[Tags]    mobile    flow    trade    market    pro    P0    TC-01`
  - TCM-08: `[Tags]    mobile    flow    trade    order_management    pro    P1    TC-08`

---

## 4. Strategi Penandaan Lintas Platform

### Klasifikasi Tag

- **Platform**
  - `api`, `web`, `mobile`
- **Domain & Jenis Skenario**
  - `flow`, `trade`
  - `market`, `limit`, `stop_limit`
  - `order_management`
  - `negative`, `validation`
  - `regulatory`, `compliance` (khusus beberapa skenario API)
- **Mode**
  - `pro`, `lite`
- **Prioritas**
  - `P0`, `P1`, `P2`
- **ID Test Bisnis**
  - `TC-xx` (TC-01 s/d TC-09 di API, TC-01 s/d TC-08 di Web/Mobile USDT/IDR)

### Contoh Pola

- API:
  - `api    flow    trade    market           pro    P0    TC-01`
  - `api    flow    trade    order_management pro    P1    TC-08`
- Web:
  - `web    flow    trade    limit            pro    P1    TC-03`
- Mobile:
  - `mobile flow    trade    stop_limit       pro    P1    TC-06`

Dengan pola ini:

- Eksekusi selektif bisa dilakukan berdasarkan:
  - Platform: hanya `api`, hanya `web`, hanya `mobile`.
  - Jenis order: hanya `limit`, hanya `stop_limit`, dsb.
  - Prioritas: hanya `P0`, atau `P0`+`P1`.
  - ID test bisnis tertentu (`TC-03`, `TC-08`, dst.).

---

## 5. Load Test & Performance (Dummy REST API)

### Tujuan

- Menyediakan contoh implementasi load/performance test yang terintegrasi
  dengan arsitektur otomasi:
  - Menggunakan Locust.
  - Memakai listener kustom untuk summary dan interpretasi hasil.
  - Memiliki assertion yang jelas terhadap respons API.
- Target awal: **maksimal target 10 RPS** terhadap dummy REST API publik.

### Target Sistem

- Public dummy API:
  - Base URL: `https://dummy.restapiexample.com`
  - Endpoint yang digunakan:
    - `GET /api/v1/employees` (get all employees)
    - `GET /api/v1/employee/{id}` (single employee)
    - `POST /api/v1/create` (create new record)

### Struktur File

- Skrip Locust:
  - `tests/performance/locust_dummy_rest_api.py`

  Berisi:

  - `DummyApiUser(HttpUser)`:
    - Mendefinisikan task:
      - `get_all_employees` (`GET /api/v1/employees`)
      - `get_single_employee` (`GET /api/v1/employee/1`)
      - `create_employee` (`POST /api/v1/create`)
    - Menggunakan `wait_time = between(wait_min, wait_max)` yang dikonfigurasi via CLI.

  - Assertion dasar di `_assert_ok_json`:
    - `status_code == 200` → jika tidak, request dianggap gagal.
    - Response harus valid JSON.
    - Jika tersedia, field `status` di payload diharapkan `success`.

  - Listener kustom:
    - `@events.request.add_listener(on_request)`:
      - Mengumpulkan:
        - `total_requests`
        - `total_failures`
        - `total_response_time_ms`
    - `@events.test_stop.add_listener(on_test_stop)`:
      - Menghitung:
        - `avg_rps` (average requests per second)
        - `avg_rt` (average response time dalam ms)
        - `failure_rate` (%)
      - Mencetak summary:

        ```text
        === Dummy REST API Load Test Summary ===
        Total requests      : <n>
        Total failures      : <n> (<xx.xx>%)
        Average RPS         : <rps>
        Average resp time   : <ms> ms
        Result              : OK / ATTENTION ...
        ```

### Opsi CLI Dinamis untuk Target RPS & Wait Time

- Skrip menambahkan opsi CLI lewat `@events.init_command_line_parser`:

  - `--target-rps` (float, default `10.0`):
    - Target average RPS yang digunakan untuk evaluasi hasil.
  - `--wait-min` (float, default `0.1`):
    - Minimum wait time antar task (detik).
  - `--wait-max` (float, default `0.3`):
    - Maksimum wait time antar task (detik).

- Pada `@events.test_start`, nilai `wait-min` dan `wait-max` dari CLI
  diaplikasikan ke `DummyApiUser.wait_time` sehingga beban bisa diatur
  tanpa mengubah kode.

- Pada `@events.test_stop`, nilai `--target-rps` dipakai untuk interpretasi:

  - Jika `avg_rps >= target_rps` dan `failure_rate < 1%`:

    ```text
    Result : OK – Target >= <target_rps> RPS tercapai dengan error rate < 1%.
    ```

  - Jika tidak:

    ```text
    Result : ATTENTION – Target <target_rps> RPS belum konsisten tercapai atau error rate tinggi.
    ```

### Contoh Eksekusi

- Contoh dasar dengan target default 10 RPS, wait time default:

  ```bash
  locust -f tests/performance/locust_dummy_rest_api.py \
         --headless \
         -u 10 -r 10 \
         -t 30s \
         -H https://dummy.restapiexample.com
  ```

- Contoh dengan target 8 RPS dan wait time lebih konservatif:

  ```bash
  locust -f tests/performance/locust_dummy_rest_api.py \
         --headless \
         -u 5 -r 5 \
         -t 5s \
         -H https://dummy.restapiexample.com \
         --target-rps 8 \
         --wait-min 0.2 \
         --wait-max 0.4
  ```

### Interpretasi Awal Hasil

- Pada beberapa run verifikasi terhadap dummy API:
  - `Average RPS` berada di kisaran 5–6 RPS untuk konfigurasi tertentu.
  - `failure_rate` 100% karena server sering merespon `HTTP 406`,
    sehingga semua request dianggap gagal oleh assertion.
- Hal ini wajar karena:
  - Endpoint dummy bersifat publik dan bisa menerapkan rate limit
    atau behavior lain yang berubah-ubah.
- Yang ingin ditonjolkan dari contoh ini:
  - Integrasi Locust + assertion + listener + interpretasi target RPS
    sudah siap di level framework.
  - Untuk sistem Indodax sendiri, design load/performance test mengikuti
    dokumen arsitektur dan akan diarahkan ke endpoint internal yang
    dikontrol penuh, bukan dummy API publik.

---

## 6. Referensi Arsitektur & Dokumen Eksternal

- **Desain Arsitektur Otomasi Pengujian Terintegrasi**
  - Dokumen Google Docs yang menjelaskan:
    - Arsitektur lintas platform (Web, API, Android, iOS).
    - Clean Architecture, SOLID, dan pemisahan layer.
    - Strategi tagging yang granular dan eksekusi berbasis tag.
    - Orkestrasi CI/CD dan integrasi reporting.
  

