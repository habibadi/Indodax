*** Settings ***
Library    Collections
Library    ../../libraries/env_loader.py

*** Keywords ***
Load Environment
    [Arguments]    ${env}
    ${config}=    Load Environment Config    ${env}
    ${PUBLIC_BASE_URL}=    Get From Dictionary    ${config}    public_base_url
    ${TRADE_BASE_URL}=    Get From Dictionary    ${config}    trade_base_url
    ${API_KEY}=    Get From Dictionary    ${config}    api_key
    ${API_SECRET}=    Get From Dictionary    ${config}    api_secret
    Set Suite Variable    ${PUBLIC_BASE_URL}
    Set Suite Variable    ${TRADE_BASE_URL}
    Set Suite Variable    ${API_KEY}
    Set Suite Variable    ${API_SECRET}
