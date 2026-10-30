*** Settings ***
Documentation    Locator หน้าดูบิลเก่า (Recall Receipt) และหน้าค้นหาการขาย


*** Comments ***
# ยกมาจากโปรเจกต์เก่า แก้ตอนรันจริงครั้งแรก 2026-10-30
# ช่อง path: ที่เหลืออิงตำแหน่ง ถ้า test พังให้เช็คตัวนี้ก่อน
# ห้ามใช้ name: ที่เป็นข้อความภาษาอังกฤษ เพราะ POS แสดงภาษาไทย


*** Variables ***
# ---------- ดูบิลเก่า (เปิดจากเมนูหลัก) ----------
${RECALL.WINDOW}                   regex:".*POS System"
${RECALL.SALE_NUM_INPUT}           automationid:txtNumber
${RECALL.OK_BUTTON}                id:DlgSearchSales > id:btnOK
# footer ของตารางสินค้า ชื่อช่อง = หัวคอลัมน์ + ยอด เช่น "ยอดขาย2,683.56"
# (เดิมใช้ path: แต่บิลยาวจนมี scrollbar ตำแหน่ง footer จะเลื่อน)
${RECALL.FOOTER}                   automationid:GridItems > name:"Footer Panel"
${RECALL.SUBTOTAL}                 ${RECALL.FOOTER} > regex:ยอดรวม
${RECALL.DISCOUNT}                 ${RECALL.FOOTER} > regex:ส่วนลด
${RECALL.TAX}                      ${RECALL.FOOTER} > regex:ภาษี
${RECALL.TOTAL}                    ${RECALL.FOOTER} > regex:ยอดขาย

# ---------- ค้นหาการขาย (เปิดจากหน้าสั่งอาหาร แสดงบิลล่าสุด) ----------
${SALE_LOOKUP.BUTTON}              automationid:btnSaleLookup
${SALE_LOOKUP.SALE_NUM_FIELD}      path:"1|8|4" and control:EditControl and automationid:txtNumber
