*** Settings ***
Resource    ../../resources/web/browser_keywords.resource
Resource    ../../resources/web/pages/market_page.resource
Library     ../../libraries/test_data_loader.py
Suite Setup    Open Browser For Web Tests
Suite Teardown    Close Browser For Web Tests
Test Template    USDTIDR Mobile Market Smoke

*** Variables ***
${ENV}    dev

*** Test Cases ***
TCM-01 Trader Executes Market Buy Order using Total Available Balance (Mobile)
    [Tags]    mobile    flow    trade    market    pro    P0    TC-01
    TC-01    ${ENV}
TCM-02 Trader Executes Market Sell Order by Specifying Asset Quantity (Mobile)
    [Tags]    mobile    flow    trade    market    pro    P0    TC-02
    TC-02    ${ENV}
TCM-03 Trader Places Limit Buy Order at a Price that Gets Filled (Mobile)
    [Tags]    mobile    flow    trade    limit    pro    P1    TC-03
    TC-03    ${ENV}
TCM-04 Trader Places Limit Sell Order resulting in Partial Execution (Mobile)
    [Tags]    mobile    flow    trade    limit    pro    P1    TC-04
    TC-04    ${ENV}
TCM-05 Trader Manages Risk with Stop-Limit Sell Order to Mitigate Loss (Mobile)
    [Tags]    mobile    flow    trade    stop_limit    pro    P1    TC-05
    TC-05    ${ENV}
TCM-06 Trader Capitalizes on Breakout with Stop-Limit Buy Order (Mobile)
    [Tags]    mobile    flow    trade    stop_limit    pro    P1    TC-06
    TC-06    ${ENV}
TCM-07 Trader is Prohibited from Trading Below Minimum Transaction Limit (Mobile)
    [Tags]    mobile    flow    trade    negative    validation    pro    P2    TC-07
    TC-07    ${ENV}
TCM-08 Trader Releases Frozen Funds by Cancelling Open Order (Mobile)
    [Tags]    mobile    flow    trade    order_management    pro    P1    TC-08
    TC-08    ${ENV}

*** Keywords ***
USDTIDR Mobile Market Smoke
    [Arguments]    ${tc_id}    ${env}
    ${scenario}=    Get Market Usdtidr Test By Id    ${tc_id}
    Run Keyword If    '${tc_id}' == 'TC-01'    Execute USDTIDR TC01 Market Buy 100 Percent    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-02'    Execute USDTIDR TC02 Market Sell Specified Quantity    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-03'    Execute USDTIDR TC03 Limit Buy Filled    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-04'    Execute USDTIDR TC04 Limit Sell Partial Execution    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-05'    Execute USDTIDR TC05 Stop Limit Sell Order    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-06'    Execute USDTIDR TC05 Stop Limit Sell Order    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-07'    Execute USDTIDR TC07 Below Minimum Transaction Limit    ${env}    ${scenario}
    Run Keyword If    '${tc_id}' == 'TC-08'    Execute USDTIDR TC08 Cancel Limit Buy To Release Frozen Funds    ${env}    ${scenario}
