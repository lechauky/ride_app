import 'package:flutter/material.dart';
import 'home_screen.dart';


  final TextEditingController user = TextEditingController();
  final TextEditingController pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng nhập")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: user, decoration: InputDecoration(labelText: "User")),
            TextField(controller: pass, decoration: InputDecoration(labelText: "Password")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => HomeScreen()));
              },
              child: Text("Login"),
            )
          ],
        ),
      ),
    );
  }
