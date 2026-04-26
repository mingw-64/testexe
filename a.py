import win32api
import win32con

def toggle_flip():
    # 1. Lấy thông tin thiết bị hiển thị chính
    device = win32api.EnumDisplayDevices(None, 0)
    
    # 2. Lấy cài đặt hiện tại (độ phân giải, hướng xoay...)
    dm = win32api.EnumDisplaySettings(device.DeviceName, win32con.ENUM_CURRENT_SETTINGS)
    
    # 3. Logic đảo chiều:
    # Nếu đang ở hướng mặc định (0), thì chuyển sang lật ngược (180)
    # Nếu đang ở bất kỳ hướng nào khác, đưa về mặc định (0)
    if dm.DisplayOrientation == win32con.DMDO_DEFAULT:
        dm.DisplayOrientation = win32con.DMDO_180
        status = "Lật ngược (180°)"
    else:
        dm.DisplayOrientation = win32con.DMDO_DEFAULT
        status = "Bình thường (0°)"
    
    # 4. Cập nhật thiết lập
    # Lưu ý: Với 180 độ ta không cần hoán đổi Width/Height như 90 hay 270 độ
    win32api.ChangeDisplaySettingsEx(device.DeviceName, dm)
    
    print(f"Trạng thái hiện tại: {status}")

if __name__ == "__main__":
    try:
        toggle_flip()
    except Exception as e:
        print(f"Có lỗi xảy ra: {e}")
