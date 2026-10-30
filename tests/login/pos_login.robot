*** Settings ***
Documentation    Flow 01 - Login ด้วย PIN (ทุก test เปิด POS ใหม่เอง)
Resource         ../../resources/keywords/login.resource
Test Setup       Close POS
Test Teardown    Finish POS Test
Test Tags        flow-01    login


*** Test Cases ***
POS-LOGIN-001 - Successful Login
    [Documentation]    PIN ถูก -> เข้าเมนูหลัก แสดงชื่อผู้ใช้
    [Tags]    smoke
    Launch And Login To POS

POS-LOGIN-002 - Invalid PIN
    [Documentation]    PIN ผิด (POS_PIN_WRONG) -> ยังอยู่หน้า Login
    Launch POS To Login Screen
    Should Not Be Empty    ${POS_PIN_WRONG}    msg=ยังไม่ได้ตั้ง POS_PIN_WRONG ใน .env
    Attempt Login With PIN    ${POS_PIN_WRONG}
    Login Screen Should Still Be Displayed After Failed Attempt

POS-LOGIN-003 - Empty PIN
    [Documentation]    ไม่กรอก PIN แล้วกด Login -> ยังอยู่หน้า Login
    Launch POS To Login Screen
    Attempt Login With PIN    ${EMPTY}
    Login Screen Should Still Be Displayed After Failed Attempt

POS-LOGIN-004 - Clear PIN
    [Documentation]    กดเลขมั่ว 3 ตัว -> Clear -> PIN จริง -> ต้อง Login ได้
    ...    (ถ้า Clear ไม่ล้างจริง เลขจะต่อท้ายกันแล้ว Login ไม่ผ่าน)
    Launch POS To Login Screen
    Attach To POS Window
    Click    id:btn1
    Click    id:btn2
    Click    id:btn3
    Enter POS PIN    ${POS_PIN}
    Click    ${LOGIN.SUBMIT_BUTTON}
    Wait Until POS Login Completes
    Main Menu Should Be Displayed For Logged In User

POS-LOGIN-005 - PIN Length Validation
    [Documentation]    PIN 3 หลัก (สั้นกว่า PIN จริง) -> Login ไม่ได้
    Launch POS To Login Screen
    Attempt Login With PIN    123
    Login Screen Should Still Be Displayed After Failed Attempt

POS-LOGIN-006 - Login After Failed Attempt
    [Documentation]    ใส่ PIN ผิดก่อน แล้ว PIN ถูก -> ต้อง Login ได้
    Launch POS To Login Screen
    Should Not Be Empty    ${POS_PIN_WRONG}    msg=ยังไม่ได้ตั้ง POS_PIN_WRONG ใน .env
    Attempt Login With PIN    ${POS_PIN_WRONG}
    Login Screen Should Still Be Displayed After Failed Attempt
    Login To POS
    Main Menu Should Be Displayed For Logged In User

POS-LOGIN-007 - Logout Then Login
    [Documentation]    Login -> Log Off -> กลับหน้า Login -> Login ใหม่ได้
    Launch POS To Login Screen
    Login To POS
    Main Menu Should Be Displayed For Logged In User
    Log Off From POS
    Verify Login Screen Is Displayed
    Login To POS
    Main Menu Should Be Displayed For Logged In User

POS-LOGIN-008 - Login State Verification
    [Documentation]    ตำแหน่ง panel เปลี่ยนจาก "หน้า Login" เป็น "Login แล้ว"
    Launch POS To Login Screen
    POS Login Panel Should Be In Visible Slot
    Login To POS
    Main Menu Should Be Displayed For Logged In User
    POS Login Panel Should Be Parked
