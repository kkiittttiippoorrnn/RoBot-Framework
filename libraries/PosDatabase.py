"""อ่านข้อมูลบิลจาก SQL Server สำหรับเช็คผลใน Flow 04-06 (SELECT อย่างเดียว)

ใช้ใน .robot / .resource:

    Library    ../../libraries/PosDatabase.py
    ...    ${POS_DB_SERVER}    ${POS_DB_NAME}    ${POS_DB_UID}    ${POS_DB_PWD}

ไม่เจอข้อมูลที่คาดไว้ -> raise AssertionError (Robot จะ FAIL test)
"""
import random
from decimal import ROUND_HALF_UP, Decimal

import pyodbc

ODBC_DRIVER = "ODBC Driver 17 for SQL Server"


def _round(value) -> float:
    """ปัดทศนิยม 2 ตำแหน่งแบบเดียวกับที่ POS แสดงบนจอ"""
    if value is None:
        return 0.0
    return float(Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


class PosDatabase:
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self, server, database, uid, pwd):
        missing = [name for name, value in
                   (("POS_DB_SERVER", server), ("POS_DB_NAME", database),
                    ("POS_DB_UID", uid), ("POS_DB_PWD", pwd)) if not value]
        if missing:
            raise ValueError(f"ยังไม่ได้ตั้ง {', '.join(missing)} ใน .env")
        self._database = database
        self._conn_str = (
            f"DRIVER={{{ODBC_DRIVER}}};SERVER={server};DATABASE={database};"
            f"UID={uid};PWD={pwd};"
        )

    def _fetch(self, sql, *params):
        conn = pyodbc.connect(self._conn_str)
        try:
            return conn.cursor().execute(sql, params).fetchall()
        finally:
            conn.close()

    def get_sale_financials(self, sale_num):
        """คืนยอดของบิลที่ปิดแล้ว: subtotal / discount / tax / total / tendered / change

        - subtotal รวมค่าบริการ (ตรงกับยอดก่อนลดบนหน้าดูบิลเก่า)
        - discount = ส่วนลดรายสินค้า (SaleItem.AmountDiscount) + ส่วนลดท้ายบิล (Sale.DiscountAmount)
        """
        rows = self._fetch(
            """
            SELECT s.SubTotal + ISNULL(s.ServiceChargeAmount, 0),
                   ISNULL(s.DiscountAmount, 0)
                   + (SELECT ISNULL(SUM(si.AmountDiscount), 0) FROM SaleItem si
                      WHERE si.SaleId = s.SaleId AND si.Active = 1),
                   s.Tax, s.Total, s.Tendered, s.Change
            FROM Sale s
            WHERE s.SaleNum = ? AND s.Active = 1 AND s.IsFinalize = 1
            """,
            sale_num,
        )
        if not rows:
            raise AssertionError(f"ไม่เจอบิลที่ปิดแล้วเลข '{sale_num}' ใน {self._database}")
        subtotal, discount, tax, total, tendered, change = rows[0]
        return {
            "subtotal": _round(subtotal),
            "discount": _round(discount),
            "tax": _round(tax),
            "total": _round(total),
            "tendered": _round(tendered),
            "change": _round(change),
        }

    def get_random_finalized_sale_num(self):
        """สุ่มเลขบิลที่ปิดแล้ว 1 ใบ (ใช้กับหน้าดูบิลเก่า)"""
        rows = self._fetch(
            """
            SELECT SaleNum FROM Sale
            WHERE ISNULL(SaleNum, '') <> '' AND IsFinalize = 1 AND Active = 1
            """
        )
        if not rows:
            raise AssertionError(f"ไม่มีบิลที่ปิดแล้วใน {self._database}")
        return random.choice(rows)[0]

    def get_sale_item_descriptions(self, sale_num):
        """คืนชื่อสินค้า (ItemDesc) ทุกบรรทัดของบิล (ชื่อรวมตัวเลือกที่ POS ต่อท้ายไว้แล้ว)"""
        rows = self._fetch(
            """
            SELECT si.ItemDesc
            FROM SaleItem si JOIN Sale s ON s.SaleId = si.SaleId
            WHERE s.SaleNum = ? AND si.Active = 1
            """,
            sale_num,
        )
        if not rows:
            raise AssertionError(f"บิล '{sale_num}' ไม่มีรายการสินค้าใน {self._database}")
        return [str(r[0]) for r in rows]

    def sale_should_contain_item(self, sale_num, expected_substring):
        """FAIL ถ้าไม่มีบรรทัดไหนที่ชื่อสินค้ามีข้อความนี้"""
        descs = self.get_sale_item_descriptions(sale_num)
        for desc in descs:
            if expected_substring in desc:
                return desc
        raise AssertionError(
            f"บิล '{sale_num}' ไม่มีสินค้า '{expected_substring}' (ที่เจอ: {', '.join(descs)})")
