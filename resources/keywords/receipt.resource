*** Settings ***
Documentation    Flow 04/05 - ดูบิลเก่า (Recall Receipt), ค้นหาการขาย และเช็คกับ DB
Variables   ../variables/environment.py
Library     String
Library     RPA.Windows
Library     ../../libraries/PosDatabase.py
...         ${POS_DB_SERVER}    ${POS_DB_NAME}    ${POS_DB_UID}    ${POS_DB_PWD}
Resource    common.resource
Resource    ../locators/login_screen.resource
Resource    ../locators/receipt_screen.resource


*** Variables ***
# รอบิลโหลดหลังกดตกลง (สูงสุด ~10 วินาที)
${RECALL_LOAD_RETRIES}       20x
${RECALL_LOAD_INTERVAL}      0.5s


*** Keywords ***
Open Recall Receipt
    Click    ${MAIN_MENU.RECALL_RECEIPT_BUTTON}
    Control Window    ${RECALL.WINDOW}

Recall Sale
    [Arguments]    ${sale_num}
    Click    ${RECALL.SALE_NUM_INPUT}
    Set Value    ${RECALL.SALE_NUM_INPUT}    ${EMPTY}
    Send Keys    ${RECALL.SALE_NUM_INPUT}    keys=${sale_num}
    Click    ${RECALL.OK_BUTTON}

Recalled Total Should Be
    [Arguments]    ${expected}
    ${total}=    Read Amount From Screen    ${RECALL.TOTAL}
    Should Be Equal As Numbers    ${total}    ${expected}    msg=ยอดสุทธิ: จอ ${total} / DB ${expected}

Recalled Amounts Should Match Database
    [Documentation]    รอจนยอดสุทธิบนจอตรง DB (= บิลโหลดเสร็จ) แล้วเทียบอีก 3 ช่อง
    ...    ยอดก่อนลดบนจอรวมค่าบริการแล้ว (ดู get_sale_financials)
    [Arguments]    ${sale_num}
    &{db}=    Get Sale Financials    ${sale_num}
    Wait Until Keyword Succeeds    ${RECALL_LOAD_RETRIES}    ${RECALL_LOAD_INTERVAL}
    ...    Recalled Total Should Be    ${db.total}
    ${subtotal}=    Read Amount From Screen    ${RECALL.SUBTOTAL}
    ${discount}=    Read Amount From Screen    ${RECALL.DISCOUNT}
    ${tax}=         Read Amount From Screen    ${RECALL.TAX}
    Should Be Equal As Numbers    ${subtotal}    ${db.subtotal}    msg=ยอดก่อนลด: จอ ${subtotal} / DB ${db.subtotal}
    Should Be Equal As Numbers    ${discount}    ${db.discount}    msg=ส่วนลด: จอ ${discount} / DB ${db.discount}
    Should Be Equal As Numbers    ${tax}    ${db.tax}    msg=ภาษี: จอ ${tax} / DB ${db.tax}

Get Latest Sale Number From Sale Lookup
    [Documentation]    เปิดค้นหาการขายจากหน้าสั่งอาหาร แล้วอ่านเลขบิลล่าสุด
    Click    ${SALE_LOOKUP.BUTTON}
    Click    ${SALE_LOOKUP.SALE_NUM_FIELD}
    ${sale_num}=    Get Element Text Or Value    ${SALE_LOOKUP.SALE_NUM_FIELD}
    ${sale_num}=    Strip String    ${sale_num}
    Should Not Be Empty    ${sale_num}    msg=หน้าค้นหาการขายไม่แสดงเลขบิล
    RETURN    ${sale_num}

Exact Cash Sale Should Be Saved In Database
    [Documentation]    เช็คบิลที่บันทึกใน DB: ยอดตรงหน้าจอ, รับเงิน = ยอด,
    ...    เงินทอน 0 (จ่ายพอดี) และมีสินค้าที่สั่ง
    [Arguments]    ${sale_num}    ${screen_total}    ${item_name}
    &{db}=    Get Sale Financials    ${sale_num}
    ${screen_total}=    Remove String    ${screen_total}    ,    ${SPACE}
    Should Be Equal As Numbers    ${db.total}    ${screen_total}    msg=ยอดสุทธิ: DB ${db.total} / จอ ${screen_total}
    Should Be Equal As Numbers    ${db.tendered}    ${db.total}    msg=รับเงิน ${db.tendered} ไม่เท่ายอด ${db.total}
    Should Be Equal As Numbers    ${db.change}    0    msg=เงินทอน ${db.change} ควรเป็น 0
    Sale Should Contain Item    ${sale_num}    ${item_name}

Cash Sale With Change Should Be Saved In Database
    [Documentation]    เช็คบิลที่จ่ายเกิน: ยอดตรงหน้าจอ, รับเงิน = ${tendered},
    ...    เงินทอน = รับเงิน - ยอด และมีสินค้าที่สั่ง
    [Arguments]    ${sale_num}    ${screen_total}    ${tendered}    ${item_name}
    &{db}=    Get Sale Financials    ${sale_num}
    ${screen_total}=    Remove String    ${screen_total}    ,    ${SPACE}
    ${expected_change}=    Evaluate    round(${tendered} - ${screen_total}, 2)
    Should Be Equal As Numbers    ${db.total}    ${screen_total}    msg=ยอดสุทธิ: DB ${db.total} / จอ ${screen_total}
    Should Be Equal As Numbers    ${db.tendered}    ${tendered}    msg=รับเงิน: DB ${db.tendered} / จ่ายจริง ${tendered}
    Should Be Equal As Numbers    ${db.change}    ${expected_change}    msg=เงินทอน: DB ${db.change} / ควรเป็น ${expected_change}
    Sale Should Contain Item    ${sale_num}    ${item_name}
