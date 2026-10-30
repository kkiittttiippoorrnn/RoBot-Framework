*** Settings ***
Documentation    Locator ขายแบบทานที่ร้าน (เปิดโต๊ะ)


*** Comments ***
# ยกมาจากโปรเจกต์เก่า แก้ตอนรันจริงครั้งแรก 2026-10-30
# POS แสดงภาษาไทย -> ใช้ชื่อ control (AutomationId) แทนข้อความบนปุ่ม
# ${DINE_IN.TABLE} อิงตำแหน่งโต๊ะ ถ้าผังโต๊ะเปลี่ยนต้องแก้


*** Variables ***
${MAIN_MENU.DINE_IN_BUTTON}        automationid:btnDineIn
${DINE_IN.WINDOW}                  regex:".*Easy Management System"
${DINE_IN.ZONE}                    automationid:pZone10
${DINE_IN.TABLE}                   path:"1|1|1|1|3|1|28"

# popup "มีคนใช้งานอยู่" เป็น MessageBox ของ Windows (อยู่ใต้หน้าต่าง POS): ปุ่ม "ใช่" มี id = 6
${TABLE_IN_USE.WINDOW}             class:#32770 and regex:"(Is in use|มีคนใช้งานอยู่)"
${TABLE_IN_USE.CONFIRM_BUTTON}     automationid:6

# หน้าต่างจำนวนลูกค้า
${GUEST_COUNT.FIELD}               control:EditControl and automationid:txtAmount
${GUEST_COUNT.OK_BUTTON}           id:DlgNumOfCust > id:btnOK

# หน้าจ่ายเงินเดียวกับ Flow 02 (ระบุ DlgPaymentW8 เพราะ btnOK มีหลายหน้าต่าง)
${DINE_IN_PAYMENT.FINALIZE_BUTTON}    id:DlgPaymentW8 > id:btnOK
${DINE_IN_PAYMENT.NO_PRINT_BUTTON}    control:ButtonControl and automationid:btnNo

# ค้นหาการขายจากหน้าโต๊ะ: แถวบิลล่าสุดย้ายตำแหน่งได้ จึงลองทีละแถว
${DINE_IN_LOOKUP.BUTTON}           id:btnSaleLookup
@{DINE_IN_LOOKUP.ROW_CANDIDATES}   path:"1|1|3|3|1|1"    path:"1|1|3|4|1|1"    path:"1|1|3|5|1|1"
${DINE_IN_LOOKUP.SALE_NUM_FIELD}   automationid:txtSaleNum
