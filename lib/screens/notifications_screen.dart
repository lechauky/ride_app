import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';

class AppNotification {
  final String id;
  final String tieuDe;
  final String noiDung;
  final String loai;
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json["id"]?.toString() ?? "",
      tieuDe: json["tieu_de"]?.toString() ?? "Thông báo",
      noiDung: json["noi_dung"]?.toString() ?? "",
      loai: json["loai"]?.toString() ?? "he_thong",
      thoiGian:
          DateTime.tryParse(json["ngay_gui"]?.toString() ?? "") ??
          DateTime.now(),
      daDoc: json["da_doc"] == true || json["da_doc"] == 1,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> items = [];
  bool isLoading = true;
  bool isUpdating = false;

  String get _city => AuthStore.currentUser.value?.thanhPho ?? "HCM";

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.get(
        "notifications?thanh_pho=$_city&limit=50",
        _city,
      );
      final data = res["data"];
      final list = data is Map ? data["data"] : null;
      if (!mounted) return;
      setState(() {
        items = list is List
            ? list
                  .whereType<Map>()
                  .map(
                    (item) => AppNotification.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((item) => item.id.isNotEmpty)
                  .toList()
            : [];
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        items = [];
        isLoading = false;
      });
    }
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

  Future<void> _markAllRead() async {
    if (isUpdating) return;
    setState(() => isUpdating = true);
    final res = await ApiService.put("notifications/read-all", _city, {
      "thanh_pho": _city,
    });
    if (!mounted) return;
    setState(() => isUpdating = false);

    if (res["data"]?["success"] == true) {
      setState(() {
        for (final n in items) {
          n.daDoc = true;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res["data"]?["message"] ?? "Không thể cập nhật thông báo",
          ),
        ),
      );
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.daDoc) return;
    final res = await ApiService.put("notifications/${n.id}/read", _city, {
      "thanh_pho": _city,
    });
    if (!mounted) return;
    if (res["data"]?["success"] == true) {
      setState(() => n.daDoc = true);
    }
  }

  Future<void> _deleteNotification(AppNotification n) async {
    final previous = [...items];
    setState(() => items.removeWhere((item) => item.id == n.id));
    final res = await ApiService.delete("notifications/${n.id}", _city, {
      "thanh_pho": _city,
    });
    if (!mounted) return;
    if (res["data"]?["success"] != true) {
      setState(() => items = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["data"]?["message"] ?? "Không thể xoá thông báo"),
        ),
      );
    }
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
          IconButton(
            tooltip: "Tải lại",
            onPressed: isLoading ? null : _fetchNotifications,
            icon: const Icon(Icons.refresh),
          ),
          if (unread > 0)
            TextButton(
              onPressed: isUpdating ? null : _markAllRead,
              child: const Text(
                "Đọc tất cả",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "Chưa có thông báo nào",
                    style: TextStyle(color: Colors.black54),
                  ),
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
                    separatorBuilder: (_, _) =>
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
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteNotification(n),
                        child: Container(
                          color: n.daDoc
                              ? Colors.white
                              : Colors.deepPurple.shade50.withValues(
                                  alpha: 0.5,
                                ),
                          child: ListTile(
                            onTap: () => _markRead(n),
                            leading: CircleAvatar(
                              backgroundColor: _colorFor(
                                n.loai,
                              ).withValues(alpha: 0.15),
                              child: Icon(
                                _iconFor(n.loai),
                                color: _colorFor(n.loai),
                              ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  n.noiDung,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _timeAgo(n.thoiGian),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
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
