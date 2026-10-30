*** Settings ***
Documentation    Flow 05 - ขายหน้าร้านแล้วเช็คบิลที่บันทึกใน DB
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/sales.resource
Resource         ../../resources/keywords/receipt.resource
Variables        ../../test-data/menu.py
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-05    e2e    db


*** Test Cases ***
POS-E2E-001 - Cash Sale Is Saved To Database
    [Documentation]    ขายสินค้า 1 รายการ จ่ายเงินสดพอดี -> บิลใน DB ต้องยอดตรงจอ
    ...    รับเงิน = ยอด, เงินทอน 0 และมีสินค้าที่สั่ง
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    Pay Exact Cash And Finish Sale    ${order_total}
    ${sale_num}=    Get Latest Sale Number From Sale Lookup
    Log    SaleNum ${sale_num}, screen total ${order_total}    console=yes
    Exact Cash Sale Should Be Saved In Database    ${sale_num}    ${order_total}    ${WALK_IN_ITEM}

POS-E2E-002 - Cash Sale With Change Is Saved To Database
    [Documentation]    ขายสินค้า 1 รายการ จ่ายเงินสดเกินยอด -> บิลใน DB ต้องยอดตรงจอ
    ...    รับเงินตรงที่จ่าย และเงินทอน = รับเงิน - ยอด
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    ${tendered}=    Get Next Round Amount    ${order_total}
    Pay Cash With Change And Finish Sale    ${order_total}    ${tendered}
    ${sale_num}=    Get Latest Sale Number From Sale Lookup
    Log    SaleNum ${sale_num}, screen total ${order_total}, tendered ${tendered}    console=yes
    Cash Sale With Change Should Be Saved In Database    ${sale_num}    ${order_total}    ${tendered}    ${WALK_IN_ITEM}
