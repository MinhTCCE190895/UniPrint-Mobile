# UniPrint Mobile - Ứng Dụng Di Động Quản Lý & Đặt In Thông Minh (PRM393)

Ứng dụng Flutter dành cho sinh viên và nhân viên quầy in thuộc hệ sinh thái **UniPrint**, được xây dựng dựa trên chuẩn giáo trình **PRM393 (Mobile Programming with Flutter)**.

---

## 📱 Kiến Trúc Dự Án (Architecture Overview)

Dự án áp dụng mô hình **Layered Architecture** chuẩn theo các Module trong `SlidePRM`:

```
uniprint_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart    # Định nghĩa URL backend (.NET 8 Web API)
│   │   │   └── app_colors.dart       # Bảng màu chuẩn UniPrint & Material Design 3
│   │   ├── network/
│   │   │   └── api_client.dart       # HTTP Client wrapper, tự động gắn JWT Bearer Token (Module 8 & 10)
│   │   └── utils/
│   │       └── storage_service.dart  # Lưu trữ Local Session qua SharedPreferences (Module 9 & 10)
│   ├── models/                       # Data Models & JSON Serialization (Module 8)
│   │   ├── user_model.dart           # UserModel, AuthResponse
│   │   ├── document_model.dart       # DocumentModel
│   │   └── print_order_model.dart    # PrintOrderModel, PriceCalculationResult, OrderStatus enum
│   ├── services/                     # Tầng gọi API qua REST (Module 8)
│   │   ├── auth_service.dart         # Đăng nhập, đăng ký, lấy profile
│   │   ├── document_service.dart     # Danh sách tài liệu cá nhân, upload metadata
│   │   └── order_service.dart        # Tính giá realtime, tạo đơn in, lấy queue, quét QR
│   ├── providers/                    # Quản lý State tập trung bằng Provider (Module 5)
│   │   ├── auth_provider.dart        # Quản lý trạng thái đăng nhập, phiên người dùng
│   │   ├── document_provider.dart    # Quản lý danh sách tài liệu
│   │   └── order_provider.dart       # Quản lý đơn in, tính giá realtime, cập nhật trạng thái
│   ├── views/                        # Giao diện người dùng (UI Screens)
│   │   ├── splash_screen.dart        # Khởi động app & kiểm tra token tự động đăng nhập (Module 10)
│   │   ├── auth/
│   │   │   └── login_screen.dart     # Màn hình đăng nhập kèm nút Autofill tài khoản mẫu (Module 7)
│   │   ├── student/
│   │   │   ├── student_home_screen.dart # Danh sách đơn in cá nhân, trạng thái, nút hủy đơn
│   │   │   ├── create_order_screen.dart # Cấu hình in, tính giá realtime theo số trang & tùy chọn
│   │   │   └── order_qr_screen.dart     # Hiển thị mã QR nhận tài liệu cho sinh viên
│   │   └── staff/
│   │       ├── staff_queue_screen.dart  # Hàng đợi in ấn cho nhân viên, cập nhật trạng thái
│   │       └── staff_qr_scanner_screen.dart # Camera quét QR hoàn tất đơn in (hoặc nhập token thủ công)
│   └── main.dart                     # Khởi tạo MultiProvider & cấu hình ThemeData
└── pubspec.yaml                      # Khai báo thư viện (provider, http, shared_preferences, qr_flutter, mobile_scanner)
```

---

## 🎯 Đối Soát Chuẩn Giáo Trình SlidePRM

| Module SlidePRM | Áp Dụng Trong UniPrint Mobile |
| :--- | :--- |
| **Module 4 & 6: UI & Responsive** | Sử dụng Material Design 3, custom widgets, Card, ListView, ModalDialog. |
| **Module 5: Navigation & State** | Dùng `provider` (`ChangeNotifier`, `ChangeNotifierProvider`, `context.watch`, `context.read`). |
| **Module 7: Forms & Validation** | Sử dụng `Form`, `GlobalKey<FormState>`, `TextFormField` với validation email & password. |
| **Module 8: RESTful API & JSON** | Dùng gói `http`, thiết kế `ApiClient`, các Model có `fromJson` và `toJson`. |
| **Module 9: Local Persistence** | Dùng `shared_preferences` lưu JWT Access Token, User ID, Role sau khi đăng nhập thành công. |
| **Module 10: Auth & Session** | Gắn `Bearer <token>` vào request header, tự động phân quyền điều hướng Sinh viên / Nhân viên tại `SplashScreen`. |

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

### 1. Cấu hình địa chỉ IP Backend
Mở file `lib/core/constants/api_endpoints.dart`:
- Nếu chạy **Android Emulator**: giữ nguyên `http://10.0.2.2:5000/api`
- Nếu chạy **Windows Desktop**: đổi thành `http://localhost:5000/api`
- Nếu chạy **Điện thoại thật**: đổi thành `http://<IP_MÁY_TÍNH_TRONG_LAN>:5000/api`

### 2. Cài đặt dependencies và chạy
```bash
flutter pub get
flutter run
```

### 3. Tài khoản demo có sẵn (có nút bấm nhanh ở màn hình Login):
- **Sinh viên**: `student@fpt.edu.vn` / `Student@123`
- **Nhân viên (Staff)**: `staff@fpt.edu.vn` / `Staff@123`
