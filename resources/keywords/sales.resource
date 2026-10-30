*** Settings ***
Documentation    Flow 02 - หน้าสั่งอาหาร, เพิ่มสินค้า Quick Sale และจ่ายเงินสด
...    (ทุก wait / re-attach มาจาก error ที่เจอตอนรันจริง ดู docs/inspection-log.md)
Library     RPA.Windows
Resource    ../locators/login_screen.resource
Resource    ../locators/sales_screen.resource
Variables   ../../test-data/menu.py


*** Variables ***
${ORDER_WINDOW_TIMEOUT}    30
# รอ POS วาดหน้าจอใหม่หลังคลิกที่เปลี่ยนหน้าจอ แล้วค่อยจับหน้าต่างใหม่
${POS_SETTLE_DELAY}        0.5s


*** Keywords ***
Open Front End
    [Documentation]    เมนูหลัก -> หน้าสั่งอาหาร
    ...    เรียก Control Window 2 ครั้งตั้งใจ: ครั้งที่ 2 จับหลัง FrmOrder โหลด control ครบ
    Click    ${MAIN_MENU.POS_BUTTON}
    Control Window    ${ORDER.WINDOW}    timeout=${ORDER_WINDOW_TIMEOUT}
    Control Window    ${ORDER.WINDOW}    timeout=${ORDER_WINDOW_TIMEOUT}

Add Quick Sale Item
    [Documentation]    หมวด -> หมวดย่อย -> สินค้า (คลิกตามชื่อ เพราะ id ของปุ่มเปลี่ยนทุกครั้ง)
    ...    หมวดและหมวดย่อยมาจาก POS_MENU_* ใน .env
    [Arguments]    ${item_name}
    Click    name:"${MENU_CATEGORY}"
    Click    name:"${MENU_SUBCATEGORY}"
    Click    name:"${item_name}"
    Sleep    ${POS_SETTLE_DELAY}
    Control Window    ${ORDER.WINDOW}

Get Order Total
    [Documentation]    ยอดรวมอยู่ที่ชื่อปุ่ม btnTotal ("0.00" ตอนยังไม่มีสินค้า)
    ${total}=    Get Attribute    ${ORDER.TOTAL_BUTTON}    Name
    RETURN    ${total}

Order Total Should Be
    [Arguments]    ${expected}
    ${total}=    Get Order Total
    Should Be Equal As Strings    ${total}    ${expected}    msg=ยอดรวม '${total}' ไม่ใช่ '${expected}'

Order Total Should Have Changed From
    [Documentation]    ใช้ยอดรวมที่เปลี่ยนเป็นหลักฐานว่าเพิ่มสินค้าแล้ว
    ...    (รายการสินค้าใน lstItems อ่านค่าไม่ได้)
    [Arguments]    ${baseline}
    ${total}=    Get Order Total
    Should Not Be Equal As Strings    ${total}    ${baseline}
    ...    msg=ยอดรวมยังเป็น '${baseline}' สินค้าน่าจะยังไม่ถูกเพิ่ม
    RETURN    ${total}

Wait Until Order Total Changes From
    [Documentation]    รอจนยอดรวมเปลี่ยน ถ้าไม่เปลี่ยนจะเก็บ UI tree ลง log ก่อน fail
    [Arguments]    ${baseline}
    TRY
        ${total}=    Wait Until Keyword Succeeds    10x    0.5s
        ...    Order Total Should Have Changed From    ${baseline}
    EXCEPT    AS    ${error}
        Capture Order Screen Diagnostic Tree
        Fail    msg=${error}
    END
    RETURN    ${total}

Capture Order Screen Diagnostic Tree
    [Documentation]    เก็บ UI tree ของ FrmOrder ลง log.html ไว้ดูตอน fail
    TRY
        Print Tree    ${ORDER.WINDOW}    max_depth=6    log_as_warnings=${True}
    EXCEPT    AS    ${error}
        Log    เก็บ UI tree ไม่ได้: ${error}    console=yes
    END

Order Screen Should Be Displayed With Reset Total
    [Documentation]    ขายเสร็จ: กลับหน้าสั่งอาหาร ยอดรวม 0.00
    Control Window    ${ORDER.WINDOW}
    Order Total Should Be    0.00

Pay Exact Cash And Finish Sale
    [Documentation]    จ่ายเงินสดพอดียอด จนกลับหน้าสั่งอาหารว่าง
    [Arguments]    ${order_total}
    Open Payment Dialog
    Payment Dialog Total Due Should Be    ${order_total}
    Select Cash Payment
    Confirm Cash Payment Amount
    Payment Should Match Total Due
    Finish Sale
    Decline Kitchen Print
    Order Screen Should Be Displayed With Reset Total

Open Payment Dialog
    Click    ${ORDER.TOTAL_BUTTON}
    Control Window    ${PAYMENT.DIALOG}

Payment Dialog Total Due Should Be
    [Arguments]    ${expected}
    ${due}=    Get Attribute    ${PAYMENT.TOTAL_DUE_FIELD}    Name
    Should Be Equal As Strings    ${due}    ${expected}
    ...    msg=ยอดที่ต้องจ่าย '${due}' ไม่ตรงกับยอดรวม '${expected}'

Select Cash Payment
    [Documentation]    กดเงินสด จะเปิดหน้าต่างใส่จำนวนเงิน (DlgAmount)
    Click    ${PAYMENT.CASH_METHOD_BUTTON}

Confirm Cash Payment Amount
    [Documentation]    กดตกลงใน DlgAmount (ใส่ยอดพอดีไว้ให้แล้ว)
    ...    ต้องจับ DlgAmount ก่อน เพราะปุ่มตกลงมี id btnOK ซ้ำกับปุ่มสิ้นสุดการขาย
    Control Window    ${PAYMENT.AMOUNT_DIALOG}
    Click    ${PAYMENT.AMOUNT_CONFIRM_BUTTON}
    Sleep    ${POS_SETTLE_DELAY}
    Control Window    ${PAYMENT.DIALOG}

Payment Should Match Total Due
    [Documentation]    รับเงิน = ยอดที่ต้องจ่าย และคงค้าง 0.00
    ${due}=    Get Attribute    ${PAYMENT.TOTAL_DUE_FIELD}    Name
    ${paid}=    Get Attribute    ${PAYMENT.PAID_FIELD}    Name
    ${balance}=    Get Attribute    ${PAYMENT.BALANCE_FIELD}    Name
    Should Be Equal As Strings    ${paid}    ${due}    msg=รับเงิน '${paid}' ไม่เท่ายอด '${due}'
    Should Be Equal As Strings    ${balance}    0.00    msg=คงค้าง '${balance}' ควรเป็น 0.00

Finish Sale
    [Documentation]    กดสิ้นสุดการขาย
    Click    ${PAYMENT.FINISH_SALE_BUTTON}

Decline Kitchen Print
    [Documentation]    ตอบ "ไม่" ตอนถามพิมพ์เข้าครัว
    Control Window    ${PRINT_KITCHEN.DIALOG}
    Click    ${PRINT_KITCHEN.DECLINE_BUTTON}
