*** Settings ***
Documentation    ตัวช่วยอ่านค่าและคลิกที่ใช้ร่วมกันใน Flow 04-06
Library     String
Library     RPA.Windows


*** Keywords ***
Get Element Text Or Value
    [Documentation]    อ่าน Name ของ control ถ้าว่างลองอ่าน Value (ช่องกรอก)
    ...    ถ้ายังว่างคืน ${fallback}
    [Arguments]    ${locator}    ${fallback}=${EMPTY}
    ${text}=    Set Variable    ${EMPTY}
    TRY
        ${text}=    Get Attribute    ${locator}    Name
    EXCEPT
        Log    อ่าน Name ไม่ได้ ลองอ่าน Value
    END
    IF    not $text
        TRY
            ${text}=    Get Value    ${locator}
        EXCEPT
            Log    อ่าน Value ไม่ได้
        END
    END
    IF    not $text    RETURN    ${fallback}
    RETURN    ${text}

Read Amount From Screen
    [Documentation]    อ่านจำนวนเงินจากหน้าจอ คืนตัวเลขตัวสุดท้ายที่เจอ (ตัด , ออก)
    ...    เช่นช่อง footer ของตารางอ่านได้ "ยอดขาย353.10" -> 353.10
    [Arguments]    ${locator}
    ${text}=    Get Element Text Or Value    ${locator}
    ${text}=    Remove String    ${text}    ,    ${SPACE}
    @{numbers}=    Get Regexp Matches    ${text}    -?\\d+(?:\\.\\d+)?
    Should Not Be Empty    ${numbers}    msg=อ่านจำนวนเงินจาก ${locator} ไม่ได้ (ข้อความ: "${text}")
    RETURN    ${numbers}[-1]

Click First Matching Locator
    [Documentation]    คลิก locator ตัวแรกที่หาเจอ (ใช้กับ control ที่ตำแหน่งเปลี่ยนได้)
    [Arguments]    @{locators}
    FOR    ${locator}    IN    @{locators}
        TRY
            Click    ${locator}
            RETURN    ${locator}
        EXCEPT
            Log    ไม่เจอ ${locator} ลองตัวถัดไป
        END
    END
    Fail    msg=ไม่เจอ locator ไหนเลย: ${locators}
