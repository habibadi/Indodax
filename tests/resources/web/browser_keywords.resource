*** Settings ***
Library    Browser

*** Variables ***
${BASE_URL}    https://indodax.com
${HEADLESS}    True

*** Keywords ***
Open Browser For Web Tests
    New Browser    chromium    headless=${HEADLESS}
    New Context
    New Page    about:blank

Close Browser For Web Tests
    Close Browser

Go To Market Page
    [Arguments]    ${path}
    Go To    ${BASE_URL}${path}

Go To History Page
    Go To    ${BASE_URL}/history

