import ctypes
from ctypes import wintypes

# Định nghĩa các hằng số
ENUM_CURRENT_SETTINGS = -1
DMDO_DEFAULT = 0
DMDO_180 = 2
DM_DISPLAYORIENTATION = 0x00800000

class DEVMODE(ctypes.Structure):
    _fields_ = [
        ("dmDeviceName", wintypes.WCHAR * 32),
        ("unused1", wintypes.WORD * 4),
        ("dmSize", wintypes.WORD),
        ("dmDriverExtra", wintypes.WORD),
        ("dmFields", wintypes.DWORD),
        ("unused2", wintypes.SHORT * 3),
        ("dmOrientation", wintypes.SHORT),
        ("dmPaperSize", wintypes.SHORT),
        ("dmPaperLength", wintypes.SHORT),
        ("dmPaperWidth", wintypes.SHORT),
        ("dmScale", wintypes.SHORT),
        ("dmCopies", wintypes.SHORT),
        ("dmDefaultSource", wintypes.SHORT),
        ("dmPrintQuality", wintypes.SHORT),
        ("dmColor", wintypes.SHORT),
        ("dmDuplex", wintypes.SHORT),
        ("dmYResolution", wintypes.SHORT),
        ("dmTTOption", wintypes.SHORT),
        ("dmCollate", wintypes.SHORT),
        ("dmFormName", wintypes.WCHAR * 32),
        ("dmLogPixels", wintypes.WORD),
        ("dmBitsPerPel", wintypes.DWORD),
        ("dmPelsWidth", wintypes.DWORD),
        ("dmPelsHeight", wintypes.DWORD),
        ("dmDisplayFlags", wintypes.DWORD),
        ("dmDisplayFrequency", wintypes.DWORD),
        ("dmICMMethod", wintypes.DWORD),
        ("dmICMIntent", wintypes.DWORD),
        ("dmMediaType", wintypes.DWORD),
        ("dmDitherType", wintypes.DWORD),
        ("dmReserved1", wintypes.DWORD),
        ("dmReserved2", wintypes.DWORD),
        ("dmPanningWidth", wintypes.DWORD),
        ("dmPanningHeight", wintypes.DWORD),
        ("dmDisplayOrientation", wintypes.DWORD),
    ]

def toggle_screen_flip():
    user32 = ctypes.windll.user32
    dm = DEVMODE()
    dm.dmSize = ctypes.sizeof(DEVMODE)

    # 1. Lấy trạng thái hiện tại
    if not user32.EnumDisplaySettingsW(None, ENUM_CURRENT_SETTINGS, ctypes.byref(dm)):
        print("Lỗi không thể đọc cài đặt màn hình.")
        return

    # 2. Kiểm tra và đảo ngược
    # Nếu đang ở 180 độ thì về 0, ngược lại thì lên 180
    if dm.dmDisplayOrientation == DMDO_180:
        new_orientation = DMDO_DEFAULT
        state_text = "Bình thường"
    else:
        new_orientation = DMDO_180
        state_text = "Lật ngược (180 độ)"

    # 3. Thiết lập thông số mới
    dm.dmDisplayOrientation = new_orientation
    dm.dmFields = DM_DISPLAYORIENTATION

    # 4. Áp dụng
    result = user32.ChangeDisplaySettingsW(ctypes.byref(dm), 0)
    
    if result == 0:
        print(f"Đã chuyển sang trạng thái: {state_text}")
    else:
        print(f"Thất bại. Mã lỗi: {result}")

if __name__ == "__main__":
    toggle_screen_flip()
