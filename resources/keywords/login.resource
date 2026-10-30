*** Settings ***
Documentation    Flow 01 - เปิด POS, Login/Logout ด้วย PIN, ปิด POS และเก็บภาพตอน fail
Library     Process
Library     RPA.Windows
Resource    ../locators/login_screen.resource
Variables   ../variables/environment.py


*** Variables ***
${POS_LAUNCH_WINDOW_TIMEOUT}    60


*** Keywords ***
Launch POS
    [Documentation]    เปิด POS ใหม่จาก POS_APP_* ใน .env
    Start Process    ${POS_APP_PATH}    cwd=${POS_APP_WORKDIR}    alias=pos

Wait For And Attach To POS Window
    [Documentation]    รอหน้าต่างหลักหลังเปิด POS (ห้ามเพิ่มการค้นหาอื่นตรงนี้
    ...    POS เปิดตัวเองซ้ำหลายรอบ จะเจอ ElementNotFound)
    Control Window    ${LOGIN.WINDOW}    timeout=${POS_LAUNCH_WINDOW_TIMEOUT}

Launch POS To Login Screen
    [Documentation]    เปิด POS แล้วรอจนหน้า Login พร้อม
    Launch POS
    Wait For And Attach To POS Window
    Verify Login Screen Is Displayed

Launch And Login To POS
    [Documentation]    เปิด POS -> Login -> ถึงเมนูหลัก
    [Arguments]    ${pin}=${POS_PIN}
    Launch POS To Login Screen
    Login To POS    ${pin}
    Main Menu Should Be Displayed For Logged In User

Close POS
    [Documentation]    ปิด POS ที่ automation เปิดไว้
    ...    1) close_pos.ps1 ปิด process ที่ไม่มี parent แล้ว (ตัวที่ถือหน้าต่างจริง)
    ...    2) ปิด process ตาม alias 'pos' ถ้ายังอยู่
    ${result}=    Run Process    powershell    -NoProfile    -File
    ...    ${PROJECT_ROOT}${/}scripts${/}close_pos.ps1    ${POS_APP_EXE_NAME}
    Log    Close POS: ${result.stdout}    console=yes
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=Cleanup error: ยังมี ${POS_APP_EXE_NAME} ค้างอยู่ - ${result.stdout} ${result.stderr}

    TRY
        Terminate Process    handle=pos
    EXCEPT    AS    ${error}
        IF    "Non-existing index or alias" in $error or "No active process" in $error
            Log    Close POS: ไม่มี process ใต้ alias 'pos' (ปิดไปเองแล้ว)    console=yes
            RETURN
        END
        Fail    msg=Cleanup error: ปิด process 'pos' ไม่ได้ - ${error}
    END
    ${still_running}=    Is Process Running    handle=pos
    Should Not Be True    ${still_running}    msg=Cleanup error: process 'pos' ยังทำงานอยู่

Finish POS Test
    [Documentation]    Test Teardown มาตรฐาน: fail แล้วถ่ายภาพหน้าจอ จากนั้นปิด POS
    Run Keyword If Test Failed    Capture Failure Screenshot
    Close POS

Capture Failure Screenshot
    [Documentation]    บันทึกภาพหน้าจอชื่อตาม test ไว้ข้าง log.html
    ...    ถ้าถ่ายไม่ได้แค่เตือน ไม่ทับ error เดิมของ test
    ${file_name}=    Evaluate    re.sub(r"[^\\w.-]+", "_", $TEST_NAME)    modules=re
    TRY
        Screenshot    desktop    ${OUTPUT_DIR}${/}${file_name}.png
    EXCEPT    AS    ${error}
        Log    ถ่ายภาพหน้าจอไม่ได้: ${error}    WARN
    END

Attach To POS Window
    Control Window    ${LOGIN.WINDOW}

Enter POS PIN
    [Documentation]    กด Clear แล้วกดตัวเลขทีละปุ่ม (PIN จะเห็นใน log.html)
    [Arguments]    ${pin}
    Click    ${LOGIN.CLEAR_BUTTON}
    @{digits}=    Evaluate    list($pin)
    FOR    ${digit}    IN    @{digits}
        Click    id:btn${digit}
    END

Login To POS
    [Arguments]    ${pin}=${POS_PIN}
    Should Not Be Empty    ${pin}    msg=ยังไม่ได้ตั้ง POS_PIN ใน .env
    Attempt Login With PIN    ${pin}
    Wait Until POS Login Completes

Attempt Login With PIN
    [Documentation]    กรอก PIN แล้วกด Login โดยไม่เช็คผล (ใช้กับเคส PIN ผิด)
    [Arguments]    ${pin}
    Attach To POS Window
    Enter POS PIN    ${pin}
    Click    ${LOGIN.SUBMIT_BUTTON}

Log Off From POS
    [Documentation]    กด Log Off แล้วกลับหน้า PIN ทันที ไม่มี popup ยืนยัน
    Click    ${MAIN_MENU.LOGOUT_BUTTON}

Get Login Panel Edges
    [Documentation]    คืนค่า (ขอบซ้ายของ pnlLogin, ขอบขวาของ pnlMenu)
    ...    ใช้ดูว่า Login แล้วหรือยัง: Login แล้ว pnlLogin จะถูกเลื่อนไปขวาของ pnlMenu
    ...    (IsOffscreen ไม่เปลี่ยน ใช้แทนไม่ได้)
    ${login_rect}=    Get Attribute    ${LOGIN.PANEL}    BoundingRectangle
    ${menu_rect}=    Get Attribute    ${MAIN_MENU.PANEL}    BoundingRectangle
    ${login_left}=    Evaluate    int($login_rect.split("(")[1].split(",")[0])
    ${menu_right}=    Evaluate    int($menu_rect.split("(")[1].split(")")[0].split(",")[2])
    RETURN    ${login_left}    ${menu_right}

POS Login Panel Should Be Parked
    [Documentation]    Login แล้ว: pnlLogin อยู่ขวาของ pnlMenu
    ${login_left}    ${menu_right}=    Get Login Panel Edges
    Should Be True    ${login_left} >= ${menu_right}
    ...    msg=ยังไม่ Login: pnlLogin ซ้าย=${login_left} ยังไม่พ้น pnlMenu ขวา=${menu_right}

POS Login Panel Should Be In Visible Slot
    [Documentation]    ยังอยู่หน้า Login: pnlLogin อยู่ในพื้นที่ที่มองเห็น
    ${login_left}    ${menu_right}=    Get Login Panel Edges
    Should Be True    ${login_left} < ${menu_right}
    ...    msg=ไม่ได้อยู่หน้า Login: pnlLogin ซ้าย=${login_left}, pnlMenu ขวา=${menu_right}

Wait Until POS Login Completes
    Wait Until Keyword Succeeds    20x    0.5s    POS Login Panel Should Be Parked

Verify Login Screen Is Displayed
    Wait Until Keyword Succeeds    20x    0.5s    POS Login Panel Should Be In Visible Slot

Login Screen Should Still Be Displayed After Failed Attempt
    Wait Until Keyword Succeeds    10x    0.5s    POS Login Panel Should Be In Visible Slot

Main Menu Should Be Displayed For Logged In User
    [Documentation]    เมนูหลักใช้งานได้: มีชื่อผู้ใช้ และปุ่ม Front End กดได้
    ${user}=    Get Attribute    ${MAIN_MENU.CURRENT_USER_LABEL}    Name
    Should Not Be Empty    ${user}    msg=ไม่แสดงชื่อผู้ใช้หลัง Login
    ${front_end_enabled}=    Get Attribute    ${MAIN_MENU.FRONT_END_RADIO}    IsEnabled
    Should Be Equal As Strings    ${front_end_enabled}    True    msg=ปุ่ม Front End กดไม่ได้
