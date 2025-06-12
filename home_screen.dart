import 'package:flutter/material.dart';
import 'package:shoponline/auth_service.dart';
import 'package:shoponline/signin_screen.dart';
import 'package:shoponline/task_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final TaskService _taskService = TaskService();
  List<Map<String, dynamic>> tasks = [];
  int updateIndex = -1;
  String searchQuery = '';
  String filterStatus = 'All';
  String? updatingTaskId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _taskService.getTasks().listen((updatedTasks) {
      setState(() {
        tasks = updatedTasks;
      });
    });
  }

  void addList(String task) async {
    if (task.isEmpty) return;
    try {
      final date = _selectedDay ?? DateTime.now();
      await _taskService.addTask(task, date);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  void updateListItem(String task, int index) async {
    if (task.isEmpty || index < 0 || index >= tasks.length) return;
    try {
      final taskId = tasks[index]['id'];
      await _taskService.updateTask(taskId, task);
      setState(() {
        updateIndex = -1;
        updatingTaskId = null;
        _controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  void deleteItem(int index) async {
    try {
      final taskId = tasks[index]['id'];
      await _taskService.deleteTask(taskId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  void toggleStatus(int index) async {
    try {
      final taskId = tasks[index]['id'];
      final isDone = tasks[index]['isDone'];
      await _taskService.toggleTaskStatus(taskId, isDone);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task status: $e')),
      );
    }
  }

  void _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  List<Map<String, dynamic>> get filteredTasks {
    final base = tasks.where((task) {
      final matchSearch = task['text'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchStatus = filterStatus == 'All' ||
          (filterStatus == 'Done' && task['isDone']) ||
          (filterStatus == 'Pending' && !task['isDone']);
      return matchSearch && matchStatus;
    }).toList();
    if (_selectedDay != null) {
      return base.where((task) {
        final createdAt = task['createdAt'] as DateTime?;
        return createdAt != null &&
          createdAt.year == _selectedDay!.year &&
          createdAt.month == _selectedDay!.month &&
          createdAt.day == _selectedDay!.day;
      }).toList();
    }
    return base;
  }

  int get completedCount => tasks.where((t) => t['isDone'] == true).length;
  int get pendingCount => tasks.where((t) => t['isDone'] == false).length;
  int get totalTasks => tasks.length;
  double getPercentage(int count) => totalTasks == 0 ? 0 : (count / totalTasks) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _signOut(context),
            tooltip: 'Logout',
          ),
        ],
        backgroundColor: const Color(0xFF9CCC65),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE7D4), Color(0xFFFFD6E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Sidebar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/get_is_done.png',
                          height: 250,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                        const SizedBox(height: 40),
                        _buildWelcomeBox(),
                        const SizedBox(height: 20),
                        _buildTaskStatusBox(),
                      ],
                    ),
                    const SizedBox(width: 60),
                    /// Main Panel
                    Expanded(
                      child: _buildTaskPanel(),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildCalendarBox(),
                const SizedBox(height: 30),
                Text(
                  'Sticky Wall',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _boxDecoration().copyWith(
                    color: Colors.white.withOpacity(0.95),
                  ),
                  child: _buildStickyNotesGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBox() {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome, User!👋🏻",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
          SizedBox(height: 10),
          Text("You're doing great today! Keep up the good work 🎯\n\nStay focused and productive. You got this! 💪",
              style: TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTaskStatusBox() {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📋 Task Status",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusCircle("Completed", getPercentage(completedCount), Colors.green),
              _buildStatusCircle("Pending", getPercentage(pendingCount), Colors.orange),
              _buildStatusCircle("Total", 100, const Color(0xFFFA5396)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPanel() {
    return Container(
      height: 700, // ✅ Tetapkan tinggi tetap
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration().copyWith(color: Colors.white.withOpacity(0.95)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Search & Filter",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: filterStatus,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      filterStatus = value;
                    });
                  }
                },
                items: ['All', 'Done', 'Pending'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// ✅ Scroll area untuk task list
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text("No tasks found. Try adding one!"))
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isDone = task['isDone'];
                      final taskText = task['text'];
                      final originalIndex = tasks.indexOf(task);
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 3,
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: Colors.green,
                            ),
                            onPressed: () => toggleStatus(originalIndex),
                          ),
                          title: Text(
                            taskText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFFFA5396)),
                                onPressed: () {
                                  setState(() {
                                    _controller.text = taskText;
                                    updateIndex = originalIndex;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFFFA5396)),
                                onPressed: () => deleteItem(originalIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),

          /// Input + Add button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Enter task...",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                onPressed: () {
                  updateIndex != -1
                      ? updateListItem(_controller.text, updateIndex)
                      : addList(_controller.text);
                },
                backgroundColor: const Color(0xFF9CCC65),
                child: Icon(updateIndex != -1 ? Icons.edit : Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCircle(String label, double percent, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text("${percent.toInt()}%"),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration().copyWith(
        color: Colors.white.withOpacity(0.95),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          return tasks.where((task) {
            final createdAt = task['createdAt'] as DateTime?;
            return createdAt != null &&
                createdAt.year == day.year &&
                createdAt.month == day.month &&
                createdAt.day == day.day;
          }).toList();
        },
      ),
    );
  }

  Widget _buildStickyNotesGrid() {
    final stickyNotes = tasks.where((t) => t['type'] == 'sticky').toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stickyNotes.length + 1, // +1 for the add button
      itemBuilder: (context, index) {
        if (index == stickyNotes.length) {
          // Add button
          return GestureDetector(
            onTap: _showAddStickyNoteDialog,
            child: Container(
              color: Colors.grey[200],
              child: Center(child: Icon(Icons.add, size: 40)),
            ),
          );
        }
        final note = stickyNotes[index];
        final color = _getNoteColor(note['color']);
        return Container(
          padding: EdgeInsets.all(16),
          color: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text(note['description'] ?? '', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Color _getNoteColor(String? color) {
    switch (color) {
      case 'yellow': return Colors.yellow[100]!;
      case 'blue': return Colors.blue[100]!;
      case 'pink': return Colors.pink[100]!;
      case 'orange': return Colors.orange[100]!;
      default: return Colors.grey[200]!;
    }
  }

  void _showAddStickyNoteDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Sticky Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _taskService.addStickyNote(
                titleController.text,
                descController.text,
                DateTime.now(),
                color: 'yellow', // or let user pick
              );
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (snapshot.hasData) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return HomeScreen();
        } else {
          return SignInScreen();
        }
      },
    );
  }
}