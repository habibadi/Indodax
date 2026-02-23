*** Settings ***
Resource    ../../resources/common/env_setup.resource

*** Test Cases ***
Load Dev Environment Should Expose Base Urls
    Load Environment    dev
    Should Be Equal As Strings    ${PUBLIC_BASE_URL}    https://indodax.com
    Should Be Equal As Strings    ${TRADE_BASE_URL}     https://indodax.com/tapi
