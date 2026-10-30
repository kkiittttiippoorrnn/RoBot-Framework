*** Settings ***
Documentation    Flow 02 - หน้าสั่งอาหาร, เพิ่มสินค้า Quick Sale และจ่ายเงินสด
...    (ทุก wait / re-attach มาจาก error ที่เจอตอนรันจริง ดู docs/inspection-log.md)
Library     RPA.Windows
Resource    ../locators/login_screen.resource
Resource    ../locators/sales_screen.resource
Resource    common.resource
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

Pay Cash With Change And Finish Sale
    [Documentation]    จ่ายเงินสดเกินยอด (${tendered}) จนกลับหน้าสั่งอาหารว่าง
    [Arguments]    ${order_total}    ${tendered}
    Open Payment Dialog
    Payment Dialog Total Due Should Be    ${order_total}
    Select Cash Payment
    Enter Cash Payment Amount    ${tendered}
    Payment Should Show Change    ${tendered}
    Finish Sale
    Decline Kitchen Print
    Change Dialog Should Show    ${order_total}    ${tendered}
    Order Screen Should Be Displayed With Reset Total

Get Next Round Amount
    [Documentation]    จำนวนเงินกลม ๆ หลักร้อยถัดไปที่มากกว่ายอด เช่น 374.50 -> 400, 400.00 -> 500
    [Arguments]    ${order_total}
    ${amount}=    Evaluate    int(float($order_total.replace(",", "")) // 100 + 1) * 100
    RETURN    ${amount}

Enter Cash Payment Amount
    [Documentation]    ล้างช่องใน DlgAmount แล้วกดตัวเลขทีละปุ่ม จากนั้นกดตกลง
    [Arguments]    ${amount}
    Control Window    ${PAYMENT.AMOUNT_DIALOG}
    Click    ${PAYMENT.AMOUNT_CLEAR_BUTTON}
    @{keys}=    Evaluate    list(str($amount))
    FOR    ${key}    IN    @{keys}
        IF    $key == "."
            Click    ${PAYMENT.AMOUNT_POINT_BUTTON}
        ELSE
            Click    id:btnNum${key}
        END
    END
    Click    ${PAYMENT.AMOUNT_CONFIRM_BUTTON}
    Sleep    ${POS_SETTLE_DELAY}
    Control Window    ${PAYMENT.DIALOG}

Payment Should Show Change
    [Documentation]    รับเงิน = ${tendered} และคงค้างติดลบเท่าเงินทอน (ยอด - รับเงิน)
    [Arguments]    ${tendered}
    ${due}=    Read Amount From Screen    ${PAYMENT.TOTAL_DUE_FIELD}
    ${paid}=    Read Amount From Screen    ${PAYMENT.PAID_FIELD}
    ${balance}=    Read Amount From Screen    ${PAYMENT.BALANCE_FIELD}
    Should Be Equal As Numbers    ${paid}    ${tendered}    msg=รับเงิน ${paid} ควรเป็น ${tendered}
    ${expected_balance}=    Evaluate    round(${due} - ${tendered}, 2)
    Should Be Equal As Numbers    ${balance}    ${expected_balance}
    ...    msg=คงค้าง ${balance} ควรเป็น ${expected_balance} (ยอด ${due} - รับเงิน ${tendered})

Get Half Amount
    [Documentation]    ครึ่งหนึ่งของยอด ปัดลงเป็นจำนวนเต็ม เช่น 374.50 -> 187
    [Arguments]    ${order_total}
    ${amount}=    Evaluate    int(float($order_total.replace(",", "")) // 2)
    RETURN    ${amount}

Payment Should Show Balance
    [Documentation]    รับเงินรวม = ${paid} และคงค้าง = ยอด - รับเงิน (ยังจ่ายไม่ครบ)
    [Arguments]    ${paid}
    ${due}=    Read Amount From Screen    ${PAYMENT.TOTAL_DUE_FIELD}
    ${shown_paid}=    Read Amount From Screen    ${PAYMENT.PAID_FIELD}
    ${balance}=    Read Amount From Screen    ${PAYMENT.BALANCE_FIELD}
    ${expected_balance}=    Evaluate    round(${due} - ${paid}, 2)
    Should Be Equal As Numbers    ${shown_paid}    ${paid}    msg=รับเงิน ${shown_paid} ควรเป็น ${paid}
    Should Be Equal As Numbers    ${balance}    ${expected_balance}    msg=คงค้าง ${balance} ควรเป็น ${expected_balance}

Payment Warning Should Appear
    [Documentation]    รอ MessageBox เตือนในหน้าจ่ายเงิน เช็คข้อความตาม regex แล้วกด OK
    [Arguments]    ${expected_text}
    Wait Until Keyword Succeeds    5s    0.2s    Get Element    ${PAYMENT.WARNING}    timeout=0.1
    ${text}=    Get Attribute    ${PAYMENT.WARNING_TEXT}    Name
    Log    คำเตือน: ${text}    console=yes
    Should Match Regexp    ${text}    ${expected_text}    msg=ข้อความเตือน "${text}" ไม่ตรงกับที่คาด
    Click    ${PAYMENT.WARNING_OK_BUTTON}
    Control Window    ${PAYMENT.DIALOG}

Finish Sale Should Be Blocked
    [Documentation]    กดสิ้นสุดการขายตอนจ่ายไม่ครบ -> ต้องเตือน "การชำระเงินไม่ถูกต้อง"
    Finish Sale
    Payment Warning Should Appear    (ไม่ถูกต้อง|not valid)

Duplicate Cash Payment Should Be Rejected
    [Documentation]    กดเงินสดซ้ำในบิลเดียว -> ต้องเตือน "การชำระเงินประเภทนี้มีอยู่แล้ว"
    Select Cash Payment
    Payment Warning Should Appear    (มีอยู่แล้ว|already exist)

Cancel Payment
    [Documentation]    กดยกเลิกในหน้าจ่ายเงิน -> กลับหน้าสั่งอาหาร
    Control Window    ${PAYMENT.DIALOG}
    Click    ${PAYMENT.CANCEL_BUTTON}
    Control Window    ${ORDER.WINDOW}

Change Dialog Should Show
    [Documentation]    หน้าต่างเงินทอนแสดง รับเงิน - ยอด แล้วกดตกลงปิด
    [Arguments]    ${order_total}    ${tendered}
    Control Window    ${CHANGE.DIALOG}
    ${change}=    Read Amount From Screen    ${CHANGE.AMOUNT_FIELD}
    ${expected}=    Evaluate    round(${tendered} - float($order_total.replace(",", "")), 2)
    Should Be Equal As Numbers    ${change}    ${expected}    msg=เงินทอนบนจอ ${change} ควรเป็น ${expected}
    Click    ${CHANGE.OK_BUTTON}

Finish Sale
    [Documentation]    กดสิ้นสุดการขาย
    Click    ${PAYMENT.FINISH_SALE_BUTTON}

Decline Kitchen Print
    [Documentation]    ตอบ "ไม่" ตอนถามพิมพ์เข้าครัว
    Control Window    ${PRINT_KITCHEN.DIALOG}
    Click    ${PRINT_KITCHEN.DECLINE_BUTTON}
