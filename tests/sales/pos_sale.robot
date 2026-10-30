*** Settings ***
Documentation    Flow 02 - ขายหน้าร้านแบบเงินสด (เช็คแค่หน้าจอ ส่วน DB อยู่ Flow 05)
...    เช็คว่าเพิ่มสินค้าแล้วจากยอดรวมที่เปลี่ยน เพราะรายการสินค้าอ่านค่าไม่ได้
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/sales.resource
Variables        ../../test-data/menu.py
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-02    sales


*** Test Cases ***
POS-SALE-001 - Basic Cash Sale
    [Documentation]    สินค้า 1 รายการ จ่ายเงินสดพอดี -> ยอดหน้าจ่ายเงินตรงยอดรวม
    ...    คงค้าง 0.00 และกลับหน้าสั่งอาหารยอด 0.00
    [Tags]    smoke
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    Pay Exact Cash And Finish Sale    ${order_total}

POS-SALE-002 - Cash Payment With Change
    [Documentation]    สินค้า 1 รายการ จ่ายเงินสดเกินยอด (หลักร้อยถัดไป) -> รับเงินตรงที่จ่าย
    ...    คงค้างติดลบเท่าเงินทอน และกลับหน้าสั่งอาหารยอด 0.00
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    ${tendered}=    Get Next Round Amount    ${order_total}
    Pay Cash With Change And Finish Sale    ${order_total}    ${tendered}

POS-SALE-003 - Multiple-Item Cash Sale
    [Documentation]    สินค้า 2 รายการ -> ยอดรวมต้องเพิ่มทุกครั้งที่เพิ่มสินค้า แล้วจ่ายเงินสดพอดี
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${first_total}=    Wait Until Order Total Changes From    0.00
    Add Quick Sale Item    ${WALK_IN_SECOND_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    ${first_total}
    ${first}=    Evaluate    float($first_total.replace(",", ""))
    ${combined}=    Evaluate    float($order_total.replace(",", ""))
    Should Be True    ${combined} > ${first}
    ...    msg=ยอดรวมไม่เพิ่มหลังเพิ่มสินค้าที่ 2 (${first_total} -> ${order_total})
    Pay Exact Cash And Finish Sale    ${order_total}
