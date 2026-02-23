*** Settings ***
Resource    ../../resources/api/auth_keywords.resource
Library     ../../resources/api/user_models.py
Library     ../../libraries/test_data_loader.py
Library     Collections
Suite Setup    Initialize Trading Flow Logging
Suite Teardown    Finalize Trading Flow Reporting    ${ENV}

*** Variables ***
${ENV}    dev
${SIMULATE_ONLY}    False

*** Test Cases ***
TC_FLOW_01_Trader_Executes_Market_Buy_Order_using_Total_Available_Balance
    [Tags]    api    flow    trade    market    pro    P0    TC-01

    Reset Trading State For Flow    TC-01

    ${flow}=    Get Trading Flow By Id    TC-01
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${percent}=    Get From Dictionary    ${flow}    percent

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-01    ${ENV}    ${pair}    ${type}    ${order_type}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${info_before}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_before}=    Validate Get Info Response    ${info_before}
    ${balance_before}=    Get From Dictionary    ${data_before}    balance
    ${idr_before}=    Get From Dictionary    ${balance_before}    idr
    ${btc_before}=    Get From Dictionary    ${balance_before}    btc

    ${idr_positive}=    Evaluate    float(${idr_before}) > 0
    Should Be True    ${idr_positive}    msg=Saldo IDR awal harus lebih dari 0 untuk TC-01

    ${idr_amount}=    Evaluate    float(${idr_before}) * float(${percent})
    ${params}=    Create Dictionary    pair=${pair}    type=${type}    order_type=${order_type}    idr=${idr_amount}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}
    ${receive_btc}=    Get From Dictionary    ${trade_data}    receive_btc

    ${info_after}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after}=    Validate Get Info Response    ${info_after}
    ${balance_after}=    Get From Dictionary    ${data_after}    balance
    ${idr_after}=    Get From Dictionary    ${balance_after}    idr
    ${btc_after}=    Get From Dictionary    ${balance_after}    btc

    Should Be Equal As Numbers    ${idr_after}    0
    ${btc_delta}=    Evaluate    float(${btc_after}) - float(${btc_before})
    Should Be Equal As Numbers    ${btc_delta}    ${receive_btc}
    Log Trading Flow Result    TC-01    ${ENV}    ${pair}    ${type}    ${order_type}    ${idr_amount}

TC_FLOW_02_Trader_Executes_Market_Sell_Order_by_Specifying_Asset_Quantity
    [Tags]    api    flow    trade    market    pro    P0    TC-02

    Reset Trading State For Flow    TC-02

    ${flow}=    Get Trading Flow By Id    TC-02
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${btc_amount}=    Get From Dictionary    ${flow}    btc

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-02    ${ENV}    ${pair}    ${type}    ${order_type}    ${btc_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    order_type=${order_type}    btc=${btc_amount}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}

    ${history_params}=    Create Dictionary    pair=${pair}    count=10    from=0
    ${history_resp}=    Call Indodax Private Method From Account    tradeHistory    ${history_params}    ${account_label}    ${ENV}
    ${trades}=    Validate Trade History Response    ${history_resp}
    ${latest}=    Get From List    ${trades}    0
    ${latest_type}=    Get From Dictionary    ${latest}    type
    ${latest_amount}=    Get From Dictionary    ${latest}    amount

    Should Be Equal As Strings    ${latest_type}    sell
    Should Be Equal As Numbers    ${latest_amount}    ${btc_amount}
    Log Trading Flow Result    TC-02    ${ENV}    ${pair}    ${type}    ${order_type}    ${btc_amount}

TC_FLOW_03_Trader_Places_Limit_Buy_Order_at_a_Price_that_Gets_Filled
    [Tags]    api    flow    trade    limit    pro    P1    TC-03

    Reset Trading State For Flow    TC-03

    ${flow}=    Get Trading Flow By Id    TC-03
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${price}=    Get From Dictionary    ${flow}    price
    ${idr_amount}=    Get From Dictionary    ${flow}    idr

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-03    ${ENV}    ${pair}    ${type}    ${order_type}    ${idr_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${info_before}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_before}=    Validate Get Info Response    ${info_before}
    ${balance_before}=    Get From Dictionary    ${data_before}    balance
    ${hold_before}=    Get From Dictionary    ${balance_before}    idr_hold

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    price=${price}    idr=${idr_amount}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}

    ${info_after}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after}=    Validate Get Info Response    ${info_after}
    ${balance_after}=    Get From Dictionary    ${data_after}    balance
    ${hold_after}=    Get From Dictionary    ${balance_after}    idr_hold

    Should Be True    ${hold_after} > ${hold_before}

    ${open_params}=    Create Dictionary    pair=${pair}
    ${open_resp}=    Call Indodax Private Method From Account    openOrders    ${open_params}    ${account_label}    ${ENV}
    ${open_data}=    Validate Open Orders Response    ${open_resp}
    Log Trading Flow Result    TC-03    ${ENV}    ${pair}    ${type}    ${order_type}    ${idr_amount}

TC_FLOW_04_Trader_Places_Limit_Sell_Order_resulting_in_Partial_Execution
    [Tags]    api    flow    trade    limit    pro    P1    TC-04

    Reset Trading State For Flow    TC-04

    ${flow}=    Get Trading Flow By Id    TC-04
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${price}=    Get From Dictionary    ${flow}    price
    ${btc_amount}=    Get From Dictionary    ${flow}    btc

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-04    ${ENV}    ${pair}    ${type}    ${order_type}    ${btc_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${info_before}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_before}=    Validate Get Info Response    ${info_before}
    ${balance_before}=    Get From Dictionary    ${data_before}    balance
    ${hold_before}=    Get From Dictionary    ${balance_before}    btc_hold

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    price=${price}    btc=${btc_amount}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}
    ${order_id}=    Get From Dictionary    ${trade_data}    order_id

    ${order_params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
    ${order_resp}=    Call Indodax Private Method From Account    getOrder    ${order_params}    ${account_label}    ${ENV}
    ${order}=    Validate Get Order Response    ${order_resp}
    ${remain_btc}=    Get From Dictionary    ${order}    remain_btc

    ${remain_positive}=    Evaluate    float(${remain_btc}) > 0
    ${remain_less}=    Evaluate    float(${remain_btc}) < float(${btc_amount})
    Should Be True    ${remain_positive}
    Should Be True    ${remain_less}

    ${cancel_params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
    ${cancel_resp}=    Call Indodax Private Method From Account    cancelOrder    ${cancel_params}    ${account_label}    ${ENV}
    ${cancel_data}=    Validate Cancel Order Response    ${cancel_resp}

    ${info_after}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after}=    Validate Get Info Response    ${info_after}
    ${balance_after}=    Get From Dictionary    ${data_after}    balance
    ${hold_after}=    Get From Dictionary    ${balance_after}    btc_hold

    ${hold_released}=    Evaluate    float(${hold_after}) <= float(${hold_before})
    Should Be True    ${hold_released}
    Log Trading Flow Result    TC-04    ${ENV}    ${pair}    ${type}    ${order_type}    ${btc_amount}

TC_FLOW_05_Trader_Manages_Risk_with_Stop_Limit_Sell_Order_to_Mitigate_Loss
    [Tags]    api    flow    trade    stop_limit    pro    P1    TC-05

    Reset Trading State For Flow    TC-05

    ${flow}=    Get Trading Flow By Id    TC-05
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${stop_price}=    Get From Dictionary    ${flow}    stop_price
    ${limit_price}=    Get From Dictionary    ${flow}    price

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-05    ${ENV}    ${pair}    ${type}    ${order_type}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    order_type=${order_type}    stop_price=${stop_price}    price=${limit_price}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}

    ${open_params}=    Create Dictionary    pair=${pair}
    ${open_resp}=    Call Indodax Private Method From Account    openOrders    ${open_params}    ${account_label}    ${ENV}
    ${open_data}=    Validate Open Orders Response    ${open_resp}
    Log Trading Flow Result    TC-05    ${ENV}    ${pair}    ${type}    ${order_type}

TC_FLOW_06_Trader_Capitalizes_on_Breakout_with_Stop_Limit_Buy_Order
    [Tags]    api    flow    trade    stop_limit    pro    P1    TC-06

    Reset Trading State For Flow    TC-06

    ${flow}=    Get Trading Flow By Id    TC-06
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${stop_price}=    Get From Dictionary    ${flow}    stop_price
    ${limit_price}=    Get From Dictionary    ${flow}    price

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-06    ${ENV}    ${pair}    ${type}    ${order_type}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    order_type=${order_type}    stop_price=${stop_price}    price=${limit_price}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}

    ${open_params}=    Create Dictionary    pair=${pair}
    ${open_resp}=    Call Indodax Private Method From Account    openOrders    ${open_params}    ${account_label}    ${ENV}
    ${open_data}=    Validate Open Orders Response    ${open_resp}

    ${history_params}=    Create Dictionary    pair=${pair}    count=10    from=0
    ${history_resp}=    Call Indodax Private Method From Account    tradeHistory    ${history_params}    ${account_label}    ${ENV}
    ${trades}=    Validate Trade History Response    ${history_resp}
    Log Trading Flow Result    TC-06    ${ENV}    ${pair}    ${type}    ${order_type}

TC_FLOW_07_Trader_is_Prohibited_from_Trading_Below_Minimum_Transaction_Limit
    [Tags]    api    flow    trade    negative    validation    lite    P2    TC-07

    Reset Trading State For Flow    TC-07

    ${flow}=    Get Trading Flow By Id    TC-07
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${idr_amount}=    Get From Dictionary    ${flow}    idr

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-07    ${ENV}    ${pair}    ${type}    amount=${idr_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${info_before}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_before}=    Validate Get Info Response    ${info_before}
    ${balance_before}=    Get From Dictionary    ${data_before}    balance
    ${idr_before}=    Get From Dictionary    ${balance_before}    idr

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    idr=${idr_amount}
    ${response}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}

    ${success}=    Get From Dictionary    ${response}    success
    Should Be Equal As Integers    ${success}    0

    ${error}=    Get From Dictionary    ${response}    error
    Should Contain    ${error}    Minimal transaksi adalah Rp25.000

    ${error_code}=    Get From Dictionary    ${response}    error_code
    Should Be Equal    ${error_code}    min_transaction_failed

    ${info_after}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after}=    Validate Get Info Response    ${info_after}
    ${balance_after}=    Get From Dictionary    ${data_after}    balance
    ${idr_after}=    Get From Dictionary    ${balance_after}    idr

    Should Be Equal As Numbers    ${idr_after}    ${idr_before}
    Log Trading Flow Result    TC-07    ${ENV}    ${pair}    ${type}    amount=${idr_amount}

TC_FLOW_08_Trader_Releases_Frozen_Funds_by_Cancelling_Open_Order
    [Tags]    api    flow    trade    order_management    pro    P1    TC-08

    Reset Trading State For Flow    TC-08

    ${flow}=    Get Trading Flow By Id    TC-08
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${order_type}=    Get From Dictionary    ${flow}    order_type
    ${price}=    Get From Dictionary    ${flow}    price
    ${idr_amount}=    Get From Dictionary    ${flow}    idr

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-08    ${ENV}    ${pair}    ${type}    ${order_type}    ${idr_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${info_before}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_before}=    Validate Get Info Response    ${info_before}
    ${balance_before}=    Get From Dictionary    ${data_before}    balance
    ${idr_before}=    Get From Dictionary    ${balance_before}    idr
    ${hold_before}=    Get From Dictionary    ${balance_before}    idr_hold

    ${trade_params}=    Create Dictionary    pair=${pair}    type=${type}    order_type=${order_type}    price=${price}    idr=${idr_amount}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${trade_params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}
    ${order_id}=    Get From Dictionary    ${trade_data}    order_id

    ${info_after_trade}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after_trade}=    Validate Get Info Response    ${info_after_trade}
    ${balance_after_trade}=    Get From Dictionary    ${data_after_trade}    balance
    ${hold_after_trade}=    Get From Dictionary    ${balance_after_trade}    idr_hold

    Should Be True    ${hold_after_trade} > ${hold_before}

    ${cancel_params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
    ${cancel_resp}=    Call Indodax Private Method From Account    cancelOrder    ${cancel_params}    ${account_label}    ${ENV}
    ${cancel_data}=    Validate Cancel Order Response    ${cancel_resp}

    ${info_after_cancel}=    Get Info From Account    ${account_label}    ${ENV}
    ${data_after_cancel}=    Validate Get Info Response    ${info_after_cancel}
    ${balance_after_cancel}=    Get From Dictionary    ${data_after_cancel}    balance
    ${idr_after}=    Get From Dictionary    ${balance_after_cancel}    idr
    ${hold_after}=    Get From Dictionary    ${balance_after_cancel}    idr_hold

    Should Be Equal As Numbers    ${idr_after}    ${idr_before}
    ${hold_released}=    Evaluate    float(${hold_after}) <= float(${hold_before})
    Should Be True    ${hold_released}
    Log Trading Flow Result    TC-08    ${ENV}    ${pair}    ${type}    ${order_type}    ${idr_amount}

TC_FLOW_09_Trader_Validates_Transaction_Settlement_after_Tax_Policy_Update
    [Tags]    api    flow    trade    regulatory    compliance    pro    P0    TC-09

    Reset Trading State For Flow    TC-09

    ${flow}=    Get Trading Flow By Id    TC-09
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    ${type}=    Get From Dictionary    ${flow}    type
    ${idr_amount}=    Get From Dictionary    ${flow}    idr
    ${timestamp}=    Get From Dictionary    ${flow}    timestamp

    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Log Trading Flow Result    TC-09    ${ENV}    ${pair}    ${type}    amount=${idr_amount}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword

    ${params}=    Create Dictionary    pair=${pair}    type=${type}    idr=${idr_amount}    timestamp=${timestamp}
    ${trade_resp}=    Call Indodax Private Method From Account    trade    ${params}    ${account_label}    ${ENV}
    ${trade_data}=    Validate Trade Response    ${trade_resp}

    ${history_params}=    Create Dictionary    pair=${pair}    count=10    from=0
    ${history_resp}=    Call Indodax Private Method From Account    tradeHistory    ${history_params}    ${account_label}    ${ENV}
    ${trades}=    Validate Trade History Response    ${history_resp}
    ${latest}=    Get From List    ${trades}    0
    ${tax}=    Get From Dictionary    ${latest}    tax

    Should Not Be Equal As Strings    ${tax}    ${EMPTY}
    Log Trading Flow Result    TC-09    ${ENV}    ${pair}    ${type}    amount=${idr_amount}

*** Keywords ***
Reset Trading State For Flow
    [Arguments]    ${tc_id}
    Run Keyword If    '${SIMULATE_ONLY}' == 'True'    Return From Keyword
    ${flow}=    Get Trading Flow By Id    ${tc_id}
    ${account_label}=    Get From Dictionary    ${flow}    account
    ${pair}=    Get From Dictionary    ${flow}    pair
    Cancel All Open Orders For Pair And Account    ${pair}    ${account_label}    ${ENV}
