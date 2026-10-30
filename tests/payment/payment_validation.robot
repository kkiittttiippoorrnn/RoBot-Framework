*** Settings ***
Documentation    Flow 03 - ตรวจกฎการชำระเงินในหน้าจ่ายเงิน
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/sales.resource
Variables        ../../test-data/menu.py
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-03    payment


*** Test Cases ***
POS-PAY-001 - Insufficient Cash Cannot Finish Sale
    [Documentation]    จ่ายเงินสดครึ่งเดียว -> คงค้างถูกต้อง -> กดสิ้นสุดการขายต้องมีคำเตือนและปิดบิลไม่ได้
    ...    -> ยกเลิกการจ่าย กลับหน้าสั่งอาหาร ยอดรวมเท่าเดิม (บิลยังไม่ปิด)
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    ${part}=    Get Half Amount    ${order_total}
    Open Payment Dialog
    Select Cash Payment
    Enter Cash Payment Amount    ${part}
    Payment Should Show Balance    ${part}
    Finish Sale Should Be Blocked
    Payment Should Show Balance    ${part}
    Cancel Payment
    Order Total Should Be    ${order_total}

POS-PAY-002 - Same Payment Method Cannot Be Added Twice
    [Documentation]    จ่ายเงินสดไปส่วนหนึ่งแล้วกดเงินสดซ้ำ -> ต้องเตือน "การชำระเงินประเภทนี้มีอยู่แล้ว"
    ...    และยอดรับเงิน / คงค้างไม่เปลี่ยน
    Launch And Login To POS
    Open Front End
    Add Quick Sale Item    ${WALK_IN_ITEM}
    ${order_total}=    Wait Until Order Total Changes From    0.00
    ${part}=    Get Half Amount    ${order_total}
    Open Payment Dialog
    Select Cash Payment
    Enter Cash Payment Amount    ${part}
    Duplicate Cash Payment Should Be Rejected
    Payment Should Show Balance    ${part}
    Cancel Payment
    Order Total Should Be    ${order_total}
