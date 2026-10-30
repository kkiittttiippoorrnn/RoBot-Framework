"""ข้อมูลเมนูที่ test ใช้ (ชื่อต้องตรงกับข้อความบนปุ่มเมนูของ POS)

ชื่อเมนูจริงอยู่ใน .env (ไม่ขึ้น git) ค่าในวงเล็บเหลี่ยมด้านล่างเป็นแค่ placeholder
ให้ dry-run / CI ทำงานได้ ถ้ารันกับ POS จริงโดยไม่ตั้งค่า จะหาปุ่มไม่เจอ

ใช้ใน suite:

    *** Settings ***
    Variables    ../../test-data/menu.py
"""
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(dotenv_path=Path(__file__).resolve().parents[1] / ".env")

# ขายหน้าร้าน (Flow 02 / 05): หมวด -> หมวดย่อย -> สินค้า (2 รายการอยู่หมวดย่อยเดียวกัน)
MENU_CATEGORY = os.getenv("POS_MENU_CATEGORY", "<CATEGORY>")
MENU_SUBCATEGORY = os.getenv("POS_MENU_SUBCATEGORY", "<SUBCATEGORY>")
WALK_IN_ITEM = os.getenv("POS_WALK_IN_ITEM", "<PRODUCT_A>")
WALK_IN_SECOND_ITEM = os.getenv("POS_WALK_IN_SECOND_ITEM", "<PRODUCT_B>")

# data-driven sale: สินค้าหลายรายการในหมวดย่อยเดียวกัน คั่นด้วย |
# (ข้อความบนปุ่มต้องตรงกับชื่อที่บันทึกลงบิล เพราะ test เช็คชื่อใน DB)
SALE_ITEMS = os.getenv(
    "POS_SALE_ITEMS", "<PRODUCT_A>|<PRODUCT_D>|<PRODUCT_E>").split("|")

# ทานที่ร้าน (Flow 06): เส้นทางเมนูตั้งแต่หมวดบนสุดจนถึงสินค้า คั่นด้วย |
DINE_IN_MENU_PATH = os.getenv(
    "POS_DINE_IN_MENU_PATH", "<CATEGORY>|<SUBCATEGORY>|<PRODUCT_C>").split("|")
DINE_IN_ITEM = DINE_IN_MENU_PATH[-1]
DINE_IN_GUEST_COUNT = 3
