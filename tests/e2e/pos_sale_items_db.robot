*** Settings ***
Documentation    Flow 05 แบบ data-driven: ขายทีละสินค้าตามตาราง แล้วเช็คบิลใน DB
...    1 แถว = 1 test ใช้ขั้นตอนเดียวกันทั้งหมด (Test Template) เปลี่ยนแค่สินค้า
...    รายชื่อสินค้ามาจาก POS_SALE_ITEMS ใน .env
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/sales.resource
Resource         ../../resources/keywords/receipt.resource
Variables        ../../test-data/menu.py
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Template    Cash Sale Of Item Should Be Saved To Database
Test Tags        flow-05    e2e    db    data-driven


*** Test Cases ***                       ITEM
POS-E2E-DD-01 - Sale Of Menu Item 1      ${SALE_ITEMS}[0]
POS-E2E-DD-02 - Sale Of Menu Item 2      ${SALE_ITEMS}[1]
POS-E2E-DD-03 - Sale Of Menu Item 3      ${SALE_ITEMS}[2]


*** Keywords ***
Cash Sale Of Item Should Be Saved To Database
    [Documentation]    ขายสินค้า 1 รายการ จ่ายเงินสดพอดี -> บิลใน DB ยอดตรงจอ
    ...    รับเงิน = ยอด, เงินทอน 0 และมีสินค้านี้
    [Arguments]    ${item}
    Set Test Documentation    สินค้า: ${item}    append=${True}
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${item}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    Pay Exact Cash And Finish Sale    ${order_total}
    ${sale_num}=    Get Latest Sale Number From Sale Lookup
    Log    ${item}: SaleNum ${sale_num}, screen total ${order_total}    console=yes
    Exact Cash Sale Should Be Saved In Database    ${sale_num}    ${order_total}    ${item}
