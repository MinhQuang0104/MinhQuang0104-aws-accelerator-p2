package kubernetes.admission

# 1. Khởi tạo danh sách lỗi mặc định là rỗng
violation[msg] {
    # 2. KIỂM TRA: Request này có phải là tạo Pod không?
    input.request.kind.kind == "Pod"

    # 3. QUÉT: Duyệt qua từng container trong mảng 'containers'
    # Biến [_, container] đóng vai trò như một vòng lặp, tự động quét sạch các phần tử
    container := input.request.object.spec.containers[_]

    # 4. ĐIỀU KIỆN LỖI: Image của container đó có kết thúc bằng ":latest" hay không?
    endswith(container.image, ":latest")

    # 5. KẾT LUẬN: Nếu cả 2, 3, 4 đều ĐÚNG, nhét thông báo này vào danh sách lỗi
    msg := sprintf("Hành vi bị chặn: Container '%v' không được dùng tag 'latest' trong môi trường Production!", [container.name])
}
