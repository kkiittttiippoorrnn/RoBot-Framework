*** Settings ***
Documentation    Locator หน้า Login และเมนูหลัก (ตรวจจาก UI tree จริง)


*** Variables ***
${LOGIN.WINDOW}                    id:FrmMainMenu3
${LOGIN.PANEL}                     id:pnlLogin
${LOGIN.SUBMIT_BUTTON}             id:btnLogin
${LOGIN.CLEAR_BUTTON}              id:btnClear

${MAIN_MENU.PANEL}                 id:pnlMenu
${MAIN_MENU.FRONT_END_RADIO}       id:rdbFrontEnd
${MAIN_MENU.POS_BUTTON}            id:btnPOS
${MAIN_MENU.RECALL_RECEIPT_BUTTON}    id:btnRecallReceipt
${MAIN_MENU.LOGOUT_BUTTON}         id:btnLogout
${MAIN_MENU.CURRENT_USER_LABEL}    id:txtUserFullName
