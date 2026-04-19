import 'package:flutter/material.dart';
import 'home_screen.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int rating = 0;
  final feedbackCtl = TextEditingController();
  final List<String> quickTags = [
    "Thái độ tốt",
    "Lái xe an toàn",
    "Đúng giờ",
    "Xe sạch sẽ",
    "Thân thiện",
    "Đi nhanh",
  ];
  final Set<String> selectedTags = {};

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

  void _submitRating() {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn số sao")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.favorite, color: Colors.pink, size: 26),
            SizedBox(width: 8),
            Text("Cảm ơn bạn!"),
          ],
        ),
        content: Text(
            "Bạn đã đánh giá $rating sao cho tài xế.\nPhản hồi của bạn giúp chúng tôi cải thiện dịch vụ."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (r) => false,
              );
            },
            child: const Text("Về trang chủ"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đánh giá tài xế"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Avatar & thông tin tài xế giả định
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person,
                        size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Nguyễn Văn A",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.directions_car,
                          size: 16, color: Colors.black54),
                      SizedBox(width: 4),
                      Text("Honda Wave • 59X1-234.56",
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _ratingLabel(),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600),
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
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickTags.map((tag) {
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
                hintText: "Chia sẻ cảm nhận của bạn về chuyến đi...",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _submitRating,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Gửi đánh giá",
                  style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false,
                );
              },
              child: const Text("Bỏ qua"),
            ),
          ],
        ),
      ),
    );
  }
}
