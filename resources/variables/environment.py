"""ไฟล์ตัวแปรของ Robot: อ่านค่าตั้งค่าและรหัสผ่านจาก environment (ไม่ฝังในโค้ด)

ใช้ในไฟล์ .robot / .resource:

    *** Settings ***
    Variables    resources/variables/environment.py

เครื่อง dev: คัดลอก .env.example เป็น .env แล้วกรอกค่า
CI: ตั้งเป็น environment variable โดยตรง
"""
import os
from pathlib import Path

from dotenv import load_dotenv

# อ่าน .env จาก root ของโปรเจกต์เสมอ ไม่ว่าจะรัน robot จากโฟลเดอร์ไหน
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(dotenv_path=_PROJECT_ROOT / ".env")

PROJECT_ROOT = str(_PROJECT_ROOT)

# ---------- POS ----------
POS_PIN = os.getenv("POS_PIN")
# PIN ที่ต้องผิด ใช้ในเคส Login ไม่ผ่าน (ต้องไม่เท่ากับ POS_PIN)
POS_PIN_WRONG = os.getenv("POS_PIN_WRONG")

POS_APP_WORKDIR = os.getenv("POS_APP_WORKDIR")
POS_APP_EXE_NAME = os.getenv("POS_APP_EXE_NAME")
POS_APP_PATH = (
    f"{POS_APP_WORKDIR}/{POS_APP_EXE_NAME}"
    if POS_APP_WORKDIR and POS_APP_EXE_NAME
    else None
)

# ---------- Database (Flow 04-06) ----------
POS_DB_SERVER = os.getenv("POS_DB_SERVER")
POS_DB_NAME = os.getenv("POS_DB_NAME")
POS_DB_UID = os.getenv("POS_DB_UID")
POS_DB_PWD = os.getenv("POS_DB_PWD")
