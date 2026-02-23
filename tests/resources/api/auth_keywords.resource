*** Settings ***
Library    RequestsLibrary
Library    ../../libraries/api_client.py
Library    ../../libraries/account_repository.py
Library    Collections
Resource   ../common/env_setup.resource

*** Variables ***
${DISCORD_WEBHOOK_TRADING_FLOW}    ${EMPTY}

*** Keywords ***
Create Indodax Public Session
    [Arguments]    ${env}=dev
    Load Environment    ${env}
    Create Session    indodax_public    ${PUBLIC_BASE_URL}

Get Indodax Public Endpoint
    [Arguments]    ${path}    ${env}=dev
    Create Indodax Public Session    ${env}
    ${response}=    Get Request    indodax_public    ${path}
    [Return]    ${response}

Create Indodax Private Session Data
    [Arguments]    ${env}=dev
    Load Environment    ${env}
    ${base_url}=    Set Variable    ${TRADE_BASE_URL}
    ${api_key}=    Set Variable    ${API_KEY}
    ${api_secret}=    Set Variable    ${API_SECRET}
    [Return]    ${base_url}    ${api_key}    ${api_secret}

Create Indodax Private Session Data From Account
    [Arguments]    ${env}    ${account_label}
    Load Environment    ${env}
    ${account}=    Get Trading Account    ${env}    ${account_label}
    ${base_url}=    Set Variable    ${TRADE_BASE_URL}
    ${api_key}=    Get From Dictionary    ${account}    api_key
    ${api_secret}=    Get From Dictionary    ${account}    api_secret
    RETURN    ${base_url}    ${api_key}    ${api_secret}

Call Indodax Private Method
    [Arguments]    ${method}    ${params}={}    ${env}=dev
    ${base_url}    ${api_key}    ${api_secret}=    Create Indodax Private Session Data    ${env}
    ${response}=    Call Private Method    ${base_url}    ${api_key}    ${api_secret}    ${method}    ${params}
    [Return]    ${response}

Call Indodax Private Method From Account
    [Arguments]    ${method}    ${params}    ${account_label}    ${env}=dev
    ${base_url}    ${api_key}    ${api_secret}=    Create Indodax Private Session Data From Account    ${env}    ${account_label}
    ${response}=    Call Private Method    ${base_url}    ${api_key}    ${api_secret}    ${method}    ${params}
    RETURN    ${response}

Get Info
    [Arguments]    ${env}=dev
    ${params}=    Create Dictionary
    ${response}=    Call Indodax Private Method    getInfo    ${params}    ${env}
    [Return]    ${response}

Get Info From Account
    [Arguments]    ${account_label}    ${env}=dev
    ${params}=    Create Dictionary
    ${response}=    Call Indodax Private Method From Account    getInfo    ${params}    ${account_label}    ${env}
    RETURN    ${response}

Trade
    [Arguments]    ${pair}    ${type}    ${price}    ${amount}    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}    type=${type}    price=${price}    amount=${amount}
    ${response}=    Call Indodax Private Method    trade    ${params}    ${env}
    [Return]    ${response}

Trade History
    [Arguments]    ${pair}    ${count}=100    ${from}=0    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}    count=${count}    from=${from}
    ${response}=    Call Indodax Private Method    tradeHistory    ${params}    ${env}
    [Return]    ${response}

Open Orders
    [Arguments]    ${pair}    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}
    ${response}=    Call Indodax Private Method    openOrders    ${params}    ${env}
    [Return]    ${response}

Order History
    [Arguments]    ${pair}    ${count}=100    ${from}=0    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}    count=${count}    from=${from}
    ${response}=    Call Indodax Private Method    orderHistory    ${params}    ${env}
    [Return]    ${response}

Get Order
    [Arguments]    ${pair}    ${order_id}    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
    ${response}=    Call Indodax Private Method    getOrder    ${params}    ${env}
    [Return]    ${response}

Cancel Order
    [Arguments]    ${pair}    ${order_id}    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
    ${response}=    Call Indodax Private Method    cancelOrder    ${params}    ${env}
    [Return]    ${response}

Cancel All Open Orders For Pair And Account
    [Arguments]    ${pair}    ${account_label}    ${env}=dev
    ${params}=    Create Dictionary    pair=${pair}
    ${response}=    Call Indodax Private Method From Account    openOrders    ${params}    ${account_label}    ${env}
    ${data}=    Validate Open Orders Response    ${response}
    ${orders}=    Get From Dictionary    ${data}    orders
    Run Keyword If    '${orders}' == '${None}'    Return From Keyword
    ${count}=    Get Length    ${orders}
    Run Keyword If    ${count} == 0    Return From Keyword
    FOR    ${order}    IN    @{orders}
        ${order_id}=    Get From Dictionary    ${order}    order_id
        ${cancel_params}=    Create Dictionary    pair=${pair}    order_id=${order_id}
        ${cancel_resp}=    Call Indodax Private Method From Account    cancelOrder    ${cancel_params}    ${account_label}    ${env}
        ${cancel_data}=    Validate Cancel Order Response    ${cancel_resp}
    END

Ensure IDR Balance At Least
    [Arguments]    ${account_label}    ${minimum_idr}    ${env}=dev
    ${info}=    Get Info From Account    ${account_label}    ${env}
    ${data}=    Validate Get Info Response    ${info}
    ${balance}=    Get From Dictionary    ${data}    balance
    ${idr}=    Get From Dictionary    ${balance}    idr
    ${ok}=    Evaluate    float(${idr}) >= float(${minimum_idr})
    Should Be True    ${ok}

Ensure BTC Balance At Least
    [Arguments]    ${account_label}    ${minimum_btc}    ${env}=dev
    ${info}=    Get Info From Account    ${account_label}    ${env}
    ${data}=    Validate Get Info Response    ${info}
    ${balance}=    Get From Dictionary    ${data}    balance
    ${btc}=    Get From Dictionary    ${balance}    btc
    ${ok}=    Evaluate    float(${btc}) >= float(${minimum_btc})
    Should Be True    ${ok}

Send Trading Flow Discord Log
    [Arguments]    ${message}    ${webhook}=${DISCORD_WEBHOOK_TRADING_FLOW}
    Run Keyword If    '${webhook}' == ''    Return From Keyword
    ${payload}=    Create Dictionary    content=${message}
    POST    ${webhook}    json=${payload}

Initialize Trading Flow Logging
    ${TRADING_FLOW_RESULTS}=    Create List
    Set Suite Variable    ${TRADING_FLOW_RESULTS}

Log Trading Flow Result
    [Arguments]    ${tc_id}    ${env}    ${pair}    ${type}    ${order_type}=${EMPTY}    ${amount}=${EMPTY}    ${status}=passed
    ${entry}=    Create Dictionary    tc_id=${tc_id}    env=${env}    pair=${pair}    type=${type}    order_type=${order_type}    amount=${amount}    status=${status}
    ${json}=    Evaluate    __import__('json').dumps(${entry})
    Log    ${json}    INFO
    Append To List    ${TRADING_FLOW_RESULTS}    ${entry}
    Set Suite Variable    ${TRADING_FLOW_RESULTS}    ${TRADING_FLOW_RESULTS}

Send Trading Flow Suite Summary
    [Arguments]    ${env}
    Run Keyword If    '${DISCORD_WEBHOOK_TRADING_FLOW}' == ''    Return From Keyword
    ${count}=    Get Length    ${TRADING_FLOW_RESULTS}
    Run Keyword If    ${count} == 0    Return From Keyword
    ${lines}=    Create List
    FOR    ${entry}    IN    @{TRADING_FLOW_RESULTS}
        ${tc_id}=    Get From Dictionary    ${entry}    tc_id
        ${pair}=    Get From Dictionary    ${entry}    pair
        ${type}=    Get From Dictionary    ${entry}    type
        ${order_type}=    Get From Dictionary    ${entry}    order_type
        ${amount}=    Get From Dictionary    ${entry}    amount
        ${status}=    Get From Dictionary    ${entry}    status
        ${line}=    Set Variable    - ${tc_id} | ${pair} | ${type}/${order_type} | amount=${amount} | status=${status}
        Append To List    ${lines}    ${line}
    END
    ${body}=    Catenate    SEPARATOR=\n    @{lines}
    ${header}=    Set Variable    Trading Flow suite (env=${env}) results:\n
    ${content}=    Catenate    SEPARATOR=    ${header}    ${body}
    Send Trading Flow Discord Log    ${content}

Send Trading Flow Artifacts
    [Arguments]    ${env}
    Run Keyword If    '${DISCORD_WEBHOOK_TRADING_FLOW}' == ''    Return From Keyword
    ${files}=    Create Dictionary
    ${status_log}    ${log_file}=    Run Keyword And Ignore Error    Get File For Streaming Upload    log.html
    Run Keyword If    '${status_log}' == 'PASS'    Set To Dictionary    ${files}    file=${log_file}
    Run Keyword If    '${status_log}' == 'PASS'    POST    ${DISCORD_WEBHOOK_TRADING_FLOW}    files=${files}

Finalize Trading Flow Reporting
    [Arguments]    ${env}
    Send Trading Flow Suite Summary    ${env}
    Send Trading Flow Artifacts    ${env}
