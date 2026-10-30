*** Settings ***
Documentation    Locator หน้าสั่งอาหาร, หน้าจ่ายเงิน และปุ่ม Quick Sale (ตรวจจาก UI tree จริง)


*** Comments ***
# ปุ่มในตาราง Quick Sale และปุ่มวิธีชำระเงิน ใช้ name: แทน id
# เพราะ AutomationId เป็นตัวเลขที่สร้างตอนรัน เปลี่ยนทุกครั้งที่ panel ถูกสร้างใหม่
# (เช่นปุ่มสินค้าเดียวกัน 856010 -> 856578) ส่วน id ที่เป็นข้อความคงที่ทุกครั้ง


*** Variables ***
${ORDER.WINDOW}                    id:FrmOrder
# id:btnTotal อย่างเดียวหาไม่เจอหลังเพิ่มสินค้า ต้องระบุ path + control ด้วย
${ORDER.TOTAL_BUTTON}              automationid:btnTotal and path:"1|1|3|1|1|1|1|1|1" and control:ButtonControl

${PAYMENT.DIALOG}                  id:DlgPaymentW8
${PAYMENT.TOTAL_DUE_FIELD}         id:txtTotalDue
${PAYMENT.PAID_FIELD}              id:txtPaid
${PAYMENT.BALANCE_FIELD}           id:txtBalance
${PAYMENT.EXACT_AMOUNT_BUTTON}     id:btnCustomerExact
${PAYMENT.FINISH_SALE_BUTTON}      id:btnOK
${PAYMENT.CASH_METHOD_BUTTON}      name:เงินสด

# หน้าต่างใส่จำนวนเงินที่เด้งหลังกดเงินสด
# ปุ่มตกลงมี id btnOK ซ้ำกับปุ่มสิ้นสุดการขาย -> ต้อง Control Window DlgAmount ก่อนกด
${PAYMENT.AMOUNT_DIALOG}           id:DlgAmount
${PAYMENT.AMOUNT_CONFIRM_BUTTON}   id:btnOK

${PRINT_KITCHEN.DIALOG}            id:DlgAskPrintKitchen
${PRINT_KITCHEN.DECLINE_BUTTON}    id:btnNo
# ปุ่มหมวด / สินค้าใน Quick Sale คลิกตามชื่อเมนูจาก test-data/menu.py
