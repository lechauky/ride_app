import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String tieuDe;
  final String noiDung;
  final String loai; // dat_xe | huy_xe | hoan_thanh | he_thong
  final DateTime thoiGian;
  bool daDoc;

  AppNotification({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.loai,
    required this.thoiGian,
    this.daDoc = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> items;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    items = [
      AppNotification(
        id: "1",
        tieuDe: "Tài xế đã đến điểm đón",
        noiDung:
            "Tài xế Nguyễn Văn A (59X1-234.56) đã đến vị trí đón của bạn.",
        loai: "dat_xe",
        thoiGian: now.subtract(const Duration(minutes: 3)),
      ),
      AppNotification(
        id: "2",
        tieuDe: "Chuyến đi hoàn thành",
        noiDung:
            "Chuyến đi từ Quận 1 đến Quận 7 đã hoàn tất. Cảm ơn bạn đã sử dụng dịch vụ!",
        loai: "hoan_thanh",
        thoiGian: now.subtract(const Duration(hours: 2)),
        daDoc: true,
      ),
      AppNotification(
        id: "3",
        tieuDe: "Khuyến mãi 30%",
        noiDung:
            "Nhập mã RIDE30 để được giảm 30% cho 3 chuyến tiếp theo của bạn.",
        loai: "he_thong",
        thoiGian: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: "4",
        tieuDe: "Chuyến đi bị hủy",
        noiDung:
            "Tài xế đã hủy chuyến đi của bạn. Hệ thống đang tìm tài xế khác.",
        loai: "huy_xe",
        thoiGian: now.subtract(const Duration(days: 1)),
        daDoc: true,
      ),
      AppNotification(
        id: "5",
        tieuDe: "Cập nhật hệ thống",
        noiDung:
            "Ride App đã cập nhật phiên bản mới với nhiều tính năng hấp dẫn.",
        loai: "he_thong",
        thoiGian: now.subtract(const Duration(days: 2)),
        daDoc: true,
      ),
    ];
  }

  IconData _iconFor(String loai) {
    switch (loai) {
      case "dat_xe":
        return Icons.directions_car;
      case "huy_xe":
        return Icons.cancel;
      case "hoan_thanh":
        return Icons.check_circle;
      case "he_thong":
      default:
        return Icons.campaign;
    }
  }

  Color _colorFor(String loai) {
    switch (loai) {
      case "dat_xe":
        return Colors.blue;
      case "huy_xe":
        return Colors.red;
      case "hoan_thanh":
        return Colors.green;
      case "he_thong":
      default:
        return Colors.orange;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return "vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }

  void _markAllRead() {
    setState(() {
      for (final n in items) {
        n.daDoc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = items.where((e) => !e.daDoc).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                "Đọc tất cả",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("Chưa có thông báo nào",
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : Column(
              children: [
                if (unread > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.deepPurple.shade50,
                    child: Text(
                      "Bạn có $unread thông báo chưa đọc",
                      style: const TextStyle(color: Colors.deepPurple),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() => items.removeAt(i));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Đã xoá: ${n.tieuDe}")),
                          );
                        },
                        child: Container(
                          color: n.daDoc
                              ? Colors.white
                              : Colors.deepPurple.shade50
                                  .withValues(alpha: 0.5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _colorFor(n.loai).withValues(alpha: 0.15),
                              child: Icon(_iconFor(n.loai),
                                  color: _colorFor(n.loai)),
                            ),
                            title: Text(
                              n.tieuDe,
                              style: TextStyle(
                                fontWeight: n.daDoc
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(n.noiDung,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  _timeAgo(n.thoiGian),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54),
                                ),
                              ],
                            ),
                            trailing: n.daDoc
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              setState(() => n.daDoc = true);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(n.tieuDe),
                                  content: Text(n.noiDung),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Đóng"),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
