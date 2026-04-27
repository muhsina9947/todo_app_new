import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Todolist(),
    );
  }
}

class Todolist extends StatefulWidget {
  const Todolist({super.key});

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  final db = FirebaseFirestore.instance;
  String? _imageUrl;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      var userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _imageUrl = userDoc.data()?['profilePic'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);

      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        Reference ref = FirebaseStorage.instance.ref().child(
          'profile_pics/$uid',
        );

        Uint8List bytes = await image.readAsBytes();

        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

        String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'profilePic': downloadUrl,
        }, SetOptions(merge: true));

        setState(() {
          _imageUrl = downloadUrl;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Photo Updated ✅")),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  void _openList(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListScreen(title: title)),
    );
  }

  void _showAddListDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.teal.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            "New List",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            height: 100,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Enter list name",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await db.collection('categories').add({
                    'name': controller.text,
                    'emoji': "📋",
                    'userId':
                        FirebaseAuth.instance.currentUser?.uid ?? "testUser",
                    'createdAt': DateTime.now().millisecondsSinceEpoch,
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "To Do App",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              currentAccountPicture: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: CircleAvatar(
                  backgroundColor: Colors.white,

                  backgroundImage: _imageUrl != null
                      ? NetworkImage(_imageUrl!)
                      : null,
                  child: (_imageUrl == null && !_isUploading)
                      ? const Icon(Icons.person, size: 40, color: Colors.teal)
                      : _isUploading
                      ? const CircularProgressIndicator(color: Colors.teal)
                      : null,
                ),
              ),

              accountName: const Text(
                "My Lists",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? "User Email",
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('categories')
                    .orderBy('createdAt')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: snapshot.data!.docs.map((doc) {
                      String categoryName = doc['name'];

                      return ListTile(
                        leading: Text(
                          doc['emoji'] ?? "📋",
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(categoryName),

                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('todo')
                              .where('list', isEqualTo: categoryName)
                              .where('isDone', isEqualTo: false)
                              .snapshots(),
                          builder: (context, taskSnapshot) {
                            if (!taskSnapshot.hasData) return const SizedBox();

                            int count = taskSnapshot.data!.docs.length;

                            if (count == 0) return const SizedBox();

                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),

                        onTap: () => _openList(categoryName),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.teal),
              title: const Text("Add List"),
              onTap: _showAddListDialog,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.teal.shade50,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("📝", style: TextStyle(fontSize: 80)),
              SizedBox(height: 20),
              Text(
                "Select a list from drawer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListScreen extends StatefulWidget {
  final String title;

  const ListScreen({super.key, required this.title});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final db = FirebaseFirestore.instance;

  void _addTask(String title) async {
    try {
      await db.collection('todo').add({
        'title': title,
        'isDone': false,
        'list': widget.title,
        'date': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? "testUser",
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Task Added ✅")));
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  void _toggleTask(String docId, bool currentValue) async {
    await db.collection('todo').doc(docId).update({'isDone': !currentValue});
  }

  void _showAddDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.teal, Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Task",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter task",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          _addTask(controller.text);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('todo')
            .where('list', isEqualTo: widget.title)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks yet"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              bool isDone = doc['isDone'] ?? false;
              return ListTile(
                leading: Checkbox(
                  value: isDone,
                  onChanged: (val) => _toggleTask(doc.id, isDone),
                ),
                title: Text(
                  doc['title'],
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => db.collection('todo').doc(doc.id).delete(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
