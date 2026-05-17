import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';

/// Đối tượng được đánh giá
/// - driver: người dùng đánh giá tài xế
/// - passenger: tài xế đánh giá khách hàng
enum RatingTarget { driver, passenger }

class RatingScreen extends StatefulWidget {
  final RatingTarget target;

  /// Tên đối tượng được đánh giá (tuỳ chọn — ví dụ tên khách / tài xế)
  final String? targetName;

  /// Thông tin phụ (vd: biển số xe khi đánh giá tài xế, SĐT khi đánh giá khách)
  final String? targetSubInfo;
  final String? tripId;
  final String? thanhPho;

  const RatingScreen({
    super.key,
    this.target = RatingTarget.driver,
    this.targetName,
    this.targetSubInfo,
    this.tripId,
    this.thanhPho,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int rating = 0;
  final feedbackCtl = TextEditingController();
  final Set<String> selectedTags = {};
  bool isSubmitting = false;

  bool get _isPassenger => widget.target == RatingTarget.passenger;
  bool get _hasTripContext =>
      widget.tripId != null && widget.tripId!.trim().isNotEmpty;

  String get _appBarTitle =>
      _isPassenger ? "Đánh giá khách hàng" : "Đánh giá tài xế";

  String get _targetLabel => _isPassenger ? "khách hàng" : "tài xế";

  String get _name =>
      widget.targetName ?? (_isPassenger ? "Khách hàng" : "Tài xế chuyến đi");

  String get _subInfo =>
      widget.targetSubInfo ??
      (widget.tripId != null
          ? "Chuyến #${widget.tripId}"
          : "Chưa có thông tin chuyến");

  IconData get _subIcon => _isPassenger ? Icons.phone : Icons.directions_car;

  IconData get _avatarIcon =>
      _isPassenger ? Icons.person_outline : Icons.person;

  /// Tag nhanh khác nhau cho 2 ngữ cảnh đánh giá
  List<String> get _quickTags => _isPassenger
      ? const [
          "Lịch sự",
          "Đúng điểm đón",
          "Không huỷ chuyến",
          "Hành lý gọn gàng",
          "Thanh toán nhanh",
          "Thân thiện",
        ]
      : const [
          "Thái độ tốt",
          "Lái xe an toàn",
          "Đúng giờ",
          "Xe sạch sẽ",
          "Thân thiện",
          "Đi nhanh",
        ];

  String get _feedbackHint => _isPassenger
      ? "Chia sẻ cảm nhận của bạn về khách hàng..."
      : "Chia sẻ cảm nhận của bạn về chuyến đi...";

  String _ratingLabel() {
    switch (rating) {
      case 1:
        return "Tệ";
      case 2:
        return "Chưa tốt";
      case 3:
        return "Bình thường";
      case 4:
        return "Tốt";
      case 5:
        return "Tuyệt vời!";
      default:
        return "Chọn số sao";
    }
  }

  @override
  void dispose() {
    feedbackCtl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _isPassenger ? const DriverHomeScreen() : const HomeScreen(),
      ),
      (r) => false,
    );
  }

  Future<void> _submitRating() async {
    if (rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn số sao")));
      return;
    }

    if (!_hasTripContext) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPassenger
                ? "Chỉ có thể đánh giá khách sau khi hoàn thành chuyến"
                : "Chỉ có thể đánh giá tài xế sau khi chuyến hoàn thành",
          ),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final user = AuthStore.currentUser.value;
      final city = widget.thanhPho ?? user?.thanhPho ?? "HCM";
      final res = await ApiService.post("trips/${widget.tripId}/rating", city, {
        "thanh_pho": city,
        "loai_nguoi_danh_gia": _isPassenger ? "driver" : "user",
        "diem_so": rating,
        "tags_nhan_xet": selectedTags.toList(),
        "nhan_xet": feedbackCtl.text.trim(),
      });

      if (!mounted) return;
      if (res["data"] == null || res["data"]["success"] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["data"]?["message"] ?? "Lỗi lưu đánh giá"),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi lưu đánh giá: $e")));
      return;
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.favorite, color: Colors.pink, size: 26),
            SizedBox(width: 8),
            Text("Cảm ơn bạn!"),
          ],
        ),
        content: Text(
          "Bạn đã đánh giá $rating sao cho $_targetLabel.\nPhản hồi của bạn giúp chúng tôi cải thiện dịch vụ.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _goHome();
            },
            child: const Text("Về trang chủ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Avatar & thông tin đối tượng được đánh giá
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(_avatarIcon, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_subIcon, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        _subInfo,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_hasTripContext) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isPassenger
                            ? "Màn này chỉ lưu đánh giá khi mở từ chuyến đã hoàn thành."
                            : "Hãy đánh giá tài xế từ chuyến đã hoàn thành để lưu vào hệ thống.",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _ratingLabel(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final active = i < rating;
                return IconButton(
                  iconSize: 44,
                  icon: Icon(
                    active ? Icons.star : Icons.star_border,
                    color: active ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => setState(() => rating = i + 1),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Quick tags
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Điểm nổi bật",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((tag) {
                final sel = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) {
                      selectedTags.add(tag);
                    } else {
                      selectedTags.remove(tag);
                    }
                  }),
                  selectedColor: Colors.deepPurple.shade100,
                  checkmarkColor: Colors.deepPurple,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Feedback text
            TextField(
              controller: feedbackCtl,
              maxLines: 4,
              maxLength: 250,
              decoration: InputDecoration(
                labelText: "Ý kiến phản hồi (tuỳ chọn)",
                hintText: _feedbackHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Gửi đánh giá", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _goHome, child: const Text("Bỏ qua")),
          ],
        ),
      ),
    );
  }
}
