*** Settings ***
Documentation    Flow 04 - ดูบิลเก่าแล้วเทียบยอดกับ DB
Resource         ../../resources/keywords/login.resource
Resource         ../../resources/keywords/receipt.resource
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-04    receipt    db


*** Variables ***
# ว่าง = สุ่มบิล / ระบุเพื่อรันซ้ำบิลเดิม: .\run.ps1 -Tests tests/receipt -Variable RECALL_SALE_NUM:RC6812230014
${RECALL_SALE_NUM}    ${EMPTY}


*** Test Cases ***
POS-RECEIPT-001 - Recall Receipt Matches Database
    [Documentation]    เปิดดูบิลเก่า -> ยอดก่อนลด / ส่วนลด / ภาษี / ยอดสุทธิ ต้องตรง DB
    ...    (เลขบิลแสดงใน report ไว้รันซ้ำด้วย RECALL_SALE_NUM)
    ${sale_num}=    IF    $RECALL_SALE_NUM    Set Variable    ${RECALL_SALE_NUM}    ELSE    Get Random Finalized Sale Num
    Log    Recalling SaleNum ${sale_num}    console=yes
    Set Test Message    SaleNum ${sale_num}
    Launch And Login To POS
    Open Recall Receipt
    Recall Sale    ${sale_num}
    Recalled Amounts Should Match Database    ${sale_num}
