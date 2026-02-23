*** Settings ***
Resource    ../browser_keywords.resource
Library    Collections

*** Variables ***
${USDTIDR_MARKET_PATH}    /market/USDTIDR
${MARKET_SELL_TITLE}    text=Market Jual
${MARKET_BUY_TITLE}    text=Market Beli
${LAST_PRICE_SECTION}    xpath=(//div[contains(@class,"datainfo")][contains(.,"Harga Terakhir")])[1]
${TRY_PRO_MODE_LINK}    xpath=//a[normalize-space(.)="Try PRO Mode"]
${BUY_TAB_MARKET}    xpath=//button[@id="headlessui-tabs-tab-v-0-1-3" and @role="tab" and @type="button"]
${SLIDER_100}    xpath=//input[@type="range" and @aria-valuemax="100" and @aria-valuetext="100%"]
${BUTTON_BUY_USDT}    xpath=//button[@id="button-buy"]
${SELL_COIN_AMOUNT_INPUT}    xpath=//div[normalize-space(.)="Sell USDT"]/preceding::input[@aria-label="Coin amount"][1]
${BUTTON_SELL_USDT}    xpath=//button[normalize-space(.)="Sell USDT"]
${LIMIT_BUY_TAB}    xpath=//button[@id="headlessui-tabs-tab-v-0-1-2"]
${BUY_PRICE_INPUT}    xpath=(//input[@aria-label="Price"])[1]
${BUY_LIMIT_SLIDER}    xpath=(//input[@type="range" and @aria-valuemax="100"])[1]
${SELL_PRICE_INPUT}    xpath=(//input[@aria-label="Price"])[2]
${OPEN_ORDER_TAB}    text=Open Order
${STOP_LIMIT_TAB}    role=tab[name="Stop Limit"]
${STOP_TRIGGER_INPUT}    xpath=(//input[@aria-label="Trigger Price"])[1]
${STOP_LIMIT_PRICE_INPUT}    xpath=(//input[@aria-label="Price"])[1]
${MIN_TX_WARNING}    text=Minimal transaksi adalah Rp25.000

*** Keywords ***
Open USDTIDR Market Page
    Go To Market Page    ${USDTIDR_MARKET_PATH}

Enter Pro Mode For USDTIDR
    Click    ${TRY_PRO_MODE_LINK}

Select Market Buy Tab
    Click    ${BUY_TAB_MARKET}

Set Buy Amount To 100 Percent
    Click    ${SLIDER_100}

Submit Buy USDT Order
    Click    ${BUTTON_BUY_USDT}

Select Limit Buy Tab
    Click    ${LIMIT_BUY_TAB}

Set Limit Buy Price
    [Arguments]    ${price}
    Fill Text    ${BUY_PRICE_INPUT}    ${price}

Set Limit Buy Slider To Half
    Click    ${BUY_LIMIT_SLIDER}

Set Limit Sell Price
    [Arguments]    ${price}
    Fill Text    ${SELL_PRICE_INPUT}    ${price}

Set Sell Coin Amount
    [Arguments]    ${amount}
    Fill Text    ${SELL_COIN_AMOUNT_INPUT}    ${amount}

Submit Sell USDT Order
    Click    ${BUTTON_SELL_USDT}

Select Stop Limit Tab
    Click    ${STOP_LIMIT_TAB}

Set Stop Limit Trigger Price
    [Arguments]    ${price}
    Fill Text    ${STOP_TRIGGER_INPUT}    ${price}

Set Stop Limit Price
    [Arguments]    ${price}
    Fill Text    ${STOP_LIMIT_PRICE_INPUT}    ${price}

Open History Page
    Go To History Page

Open Open Order Tab
    Click    ${OPEN_ORDER_TAB}

Cancel First Open Order
    Click    text=Cancel

Market Sections Should Be Visible
    Get Text    ${MARKET_SELL_TITLE}
    Get Text    ${MARKET_BUY_TITLE}

Last Price Should Be Present
    ${text}=    Get Text    ${LAST_PRICE_SECTION}
    ${has_number}=    Evaluate    __import__("re").search(r"[0-9][0-9\\.,]*", ${text}) is not None
    Should Be True    ${has_number}

Minimum Transaction Warning Should Be Visible
    Get Text    ${MIN_TX_WARNING}

Execute USDTIDR TC01 Market Buy 100 Percent
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Market Buy Tab
    Set Buy Amount To 100 Percent
    Submit Buy USDT Order
    Market Sections Should Be Visible
    Last Price Should Be Present

Execute USDTIDR TC02 Market Sell Specified Quantity
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Market Buy Tab
    ${amount}=    Get From Dictionary    ${scenario}    sell_amount
    Set Sell Coin Amount    ${amount}
    Submit Sell USDT Order
    Market Sections Should Be Visible
    Last Price Should Be Present

Execute USDTIDR TC03 Limit Buy Filled
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Limit Buy Tab
    ${price}=    Get From Dictionary    ${scenario}    limit_price
    Set Limit Buy Price    ${price}
    Set Limit Buy Slider To Half
    Submit Buy USDT Order
    Market Sections Should Be Visible
    Last Price Should Be Present

Execute USDTIDR TC04 Limit Sell Partial Execution
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Limit Buy Tab
    ${price}=    Get From Dictionary    ${scenario}    limit_sell_price
    ${amount}=    Get From Dictionary    ${scenario}    sell_amount
    Set Limit Sell Price    ${price}
    Set Sell Coin Amount    ${amount}
    Submit Sell USDT Order
    Market Sections Should Be Visible
    Last Price Should Be Present
    Open History Page
    Open Open Order Tab

Execute USDTIDR TC05 Stop Limit Sell Order
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Stop Limit Tab
    ${stop_price}=    Get From Dictionary    ${scenario}    stop_price
    ${limit_price}=    Get From Dictionary    ${scenario}    limit_price
    Set Stop Limit Trigger Price    ${stop_price}
    Set Stop Limit Price    ${limit_price}
    Submit Sell USDT Order
    Market Sections Should Be Visible
    Last Price Should Be Present

Execute USDTIDR TC08 Cancel Limit Buy To Release Frozen Funds
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Limit Buy Tab
    ${price}=    Get From Dictionary    ${scenario}    limit_price
    Set Limit Buy Price    ${price}
    Set Limit Buy Slider To Half
    Submit Buy USDT Order
    Open History Page
    Open Open Order Tab
    Cancel First Open Order

Execute USDTIDR TC07 Below Minimum Transaction Limit
    [Arguments]    ${env}    ${scenario}
    Open USDTIDR Market Page
    Enter Pro Mode For USDTIDR
    Select Market Buy Tab
    ${amount}=    Get From Dictionary    ${scenario}    invalid_amount_idr
    Set Sell Coin Amount    ${amount}
    Submit Buy USDT Order
    Minimum Transaction Warning Should Be Visible
