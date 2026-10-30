*** Settings ***
Documentation    Flow 06 - ขายแบบทานที่ร้าน (เปิดโต๊ะ) แล้วเช็คบิลที่บันทึกใน DB
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/dine_in.resource
Resource         ../../resources/keywords/receipt.resource
Variables        ../../test-data/menu.py
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-06    dine-in    db


*** Test Cases ***
POS-DINEIN-001 - Dine-in Sale Is Saved To Database
    [Documentation]    เปิดโต๊ะ สั่ง 1 รายการ จ่ายพอดี -> บิลใน DB ต้องยอดตรงจอ
    ...    รับเงิน = ยอด, เงินทอน 0 และมีสินค้าที่สั่ง
    Launch And Login To POS
    Open Dine In Table
    Enter Guest Count    ${DINE_IN_GUEST_COUNT}
    Add Item Via Menu Path    @{DINE_IN_MENU_PATH}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    Pay Exact And Finalize Dine In Sale
    ${sale_num}=    Get Latest Dine In Sale Number
    Log    SaleNum ${sale_num}, screen total ${order_total}    console=yes
    Exact Cash Sale Should Be Saved In Database    ${sale_num}    ${order_total}    ${DINE_IN_ITEM}
