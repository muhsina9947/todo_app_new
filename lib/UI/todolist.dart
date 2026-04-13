import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  List<String> lists = ["My Day", "Important", "Work", "Groceries"];

  Map<String, String> listEmojis = {
    "My Day": "☀️",
    "Important": "⭐",
    "Work": "💼",
    "Groceries": "🍉",
  };

  void _openList(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(title: title, listEmojis: listEmojis),
      ),
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
          content: Container(
            width: 300, // 🔥 increase width
            height: 150, // 🔥 increase height
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
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    lists.add(controller.text);
                    listEmojis[controller.text] = "📋";
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
        title: const Text("To Do App"),
        backgroundColor: Colors.teal,
         actions: [
    IconButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          // Navigate back to Loginpage (Ensure you import it)
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
      icon: const Icon(Icons.logout),
    ),
  ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                "My Lists",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ...lists.map(
              (list) => ListTile(
                leading: Text(
                  listEmojis[list] ?? "📋",
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(list),
                onTap: () => _openList(list),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.teal),
              title: const Text("Add List"),
              onTap: _showAddListDialog,
            ),
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
  final Map<String, String> listEmojis;

  const ListScreen({super.key, required this.title, required this.listEmojis});

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
        'date': Timestamp.now(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? "testUser",
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Task Added ✅")));

      print("✅ Task Added");
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  void _toggleTask(String docId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('todo').doc(docId).update({
      'isDone': !currentValue,
    });
  }

  void _showAddDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent, // 🔥 important
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
                        }
                        Navigator.pop(context);
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
        title: Text("${widget.listEmojis[widget.title]} ${widget.title}"),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.teal.shade50,
        child: StreamBuilder(
          stream: db
              .collection('todo')
              .where('list', isEqualTo: widget.title)
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.listEmojis[widget.title] ?? "📝",
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 20),
                    const Text("Start your tasks"),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                var data = doc.data() as Map<String, dynamic>;
                print(data['title']);

                return Dismissible(
                  key: Key(doc.id),
                  onDismissed: (_) async {
                    await db.collection('todo').doc(doc.id).delete();
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    leading: Checkbox(
                      value: data['isDone'] ?? false,
                      onChanged: (value) {
                        _toggleTask(doc.id, data['isDone'] ?? false);
                      },
                    ),
                    title: Text(data['title'] ?? ''),
                    subtitle: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['date'] != null
                                ? DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format((data['date'] as Timestamp).toDate())
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
