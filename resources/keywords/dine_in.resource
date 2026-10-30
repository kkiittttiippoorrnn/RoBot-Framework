*** Settings ***
Documentation    Flow 06 - ขายแบบทานที่ร้าน (เปิดโต๊ะ)
Library     String
Library     RPA.Windows
Resource    common.resource
Resource    sales.resource
Resource    ../locators/dine_in_screen.resource


*** Variables ***
${DINE_IN_WINDOW_TIMEOUT}    60
# รอหน้าต่างจำนวนลูกค้า โดยเช็คซ้ำทุก ${POLL_INTERVAL}
${GUEST_COUNT_TIMEOUT}       10s
${POLL_INTERVAL}             0.2s


*** Keywords ***
Open Dine In Table
    [Documentation]    เมนูหลัก -> ทานที่ร้าน -> โซน -> โต๊ะ -> รอหน้าต่างจำนวนลูกค้า
    Click    ${MAIN_MENU.DINE_IN_BUTTON}
    Control Window    ${DINE_IN.WINDOW}    timeout=${DINE_IN_WINDOW_TIMEOUT}
    Click    ${DINE_IN.ZONE}
    Click    ${DINE_IN.TABLE}
    Wait Until Keyword Succeeds    ${GUEST_COUNT_TIMEOUT}    ${POLL_INTERVAL}
    ...    Guest Count Dialog Should Be Open

Guest Count Dialog Should Be Open
    [Documentation]    เช็คครั้งเดียว: หน้าต่างจำนวนลูกค้าขึ้นแล้วหรือยัง
    ...    ถ้าเจอ popup "มีคนใช้งานอยู่" (โต๊ะค้างจากรอบก่อน) กดใช่ แล้วให้รอบถัดไปเช็คใหม่
    ...    ค้นในหน้าต่าง POS (dialog อยู่ใต้หน้าต่างนี้) แทน Control Window ที่ค้นทั้งจอ ~16 วินาที
    ${opened}=    Run Keyword And Return Status    Get Element    ${GUEST_COUNT.FIELD}    timeout=0.1
    IF    ${opened}    RETURN
    ${in_use}=    Run Keyword And Return Status    Get Element    ${TABLE_IN_USE.WINDOW}    timeout=0.1
    IF    ${in_use}
        Log    เจอ popup โต๊ะถูกใช้งาน กดใช่    console=yes
        Click    ${TABLE_IN_USE.WINDOW} > ${TABLE_IN_USE.CONFIRM_BUTTON}
    END
    Fail    หน้าต่างจำนวนลูกค้ายังไม่ขึ้น

Enter Guest Count
    [Arguments]    ${guests}
    Click    ${GUEST_COUNT.FIELD}
    Send Keys    ${GUEST_COUNT.FIELD}    keys=${guests}
    Click    ${GUEST_COUNT.OK_BUTTON}

Add Item Via Menu Path
    [Documentation]    คลิกเมนูตามชื่อทีละชั้น (หมวด -> ... -> สินค้า) แล้วรอหน้าจอนิ่ง
    [Arguments]    @{menu_path}
    FOR    ${level}    IN    @{menu_path}
        Click    name:"${level}"
    END
    Sleep    ${POS_SETTLE_DELAY}
    Control Window    ${DINE_IN.WINDOW}

Pay Exact And Finalize Dine In Sale
    [Documentation]    ยอดรวม -> จ่ายพอดี -> สิ้นสุดการขาย -> ไม่พิมพ์ใบเสร็จ
    Click    ${ORDER.TOTAL_BUTTON}
    Click    ${PAYMENT.EXACT_AMOUNT_BUTTON}
    Click    ${DINE_IN_PAYMENT.FINALIZE_BUTTON}
    Click    ${DINE_IN_PAYMENT.NO_PRINT_BUTTON}

Get Latest Dine In Sale Number
    [Documentation]    เปิดค้นหาการขายจากหน้าโต๊ะ แล้วอ่านเลขบิลล่าสุด
    Control Window    ${DINE_IN.WINDOW}    timeout=${DINE_IN_WINDOW_TIMEOUT}
    Click    ${DINE_IN_LOOKUP.BUTTON}
    Click First Matching Locator    @{DINE_IN_LOOKUP.ROW_CANDIDATES}
    ${sale_num}=    Get Element Text Or Value    ${DINE_IN_LOOKUP.SALE_NUM_FIELD}
    ${sale_num}=    Strip String    ${sale_num}
    Should Not Be Empty    ${sale_num}    msg=หน้าค้นหาการขายไม่แสดงเลขบิล
    RETURN    ${sale_num}
