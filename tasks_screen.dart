import 'package:flutter/material.dart';
import '../logic/task_controller.dart';
import '../sql/database_helper.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskController _controller = TaskController();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _controller.getAllTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'متوسط';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إضافة مهمة جديدة',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          textDirection: TextDirection.rtl,
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('عنوان المهمة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('الوصف (اختياري)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                dropdownColor: const Color(0xFF2A2A3E),
                decoration: _inputDecoration('الأولوية'),
                style: const TextStyle(color: Colors.white),
                items: ['منخفض', 'متوسط', 'عالي']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, textDirection: TextDirection.rtl)))
                    .toList(),
                onChanged: (val) => setStateDialog(() => priority = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6AF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              await _controller.addTask(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                priority: priority,
              );
              Navigator.pop(ctx);
              _loadTasks();
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
      filled: true,
      fillColor: const Color(0xFF2A2A3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'عالي':
        return const Color(0xFFFF6B6B);
      case 'متوسط':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFF6BCB77);
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'عالي':
        return Icons.priority_high_rounded;
      case 'متوسط':
        return Icons.remove_rounded;
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _tasks.where((t) => t['is_done'] == 0).length;
    final doneCount = _tasks.where((t) => t['is_done'] == 1).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF12121F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'مدير المهام',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _StatCard(label: 'قيد التنفيذ', count: pendingCount, color: const Color(0xFF7C6AF7)),
                  const SizedBox(width: 12),
                  _StatCard(label: 'مكتملة', count: doneCount, color: const Color(0xFF6BCB77)),
                  const SizedBox(width: 12),
                  _StatCard(label: 'الكل', count: _tasks.length, color: const Color(0xFF4ECDC4)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7)))
                  : _tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مهام بعد\nاضغط + لإضافة مهمة',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _tasks.length,
                          itemBuilder: (ctx, i) {
                            final task = _tasks[i];
                            final isDone = task['is_done'] == 1;
                            final priority = task['priority'] ?? 'متوسط';

                            return Dismissible(
                              key: Key(task['id'].toString()),
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                await _controller.deleteTask(task['id']);
                                _loadTasks();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFF1A1A2E).withOpacity(0.6)
                                      : const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDone
                                        ? Colors.grey.withOpacity(0.2)
                                        : _priorityColor(priority).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: GestureDetector(
                                    onTap: () async {
                                      await _controller.toggleTask(task['id'], isDone);
                                      _loadTasks();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDone ? const Color(0xFF6BCB77) : Colors.transparent,
                                        border: Border.all(
                                          color: isDone ? const Color(0xFF6BCB77) : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: isDone
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ),
                                  title: Text(
                                    task['title'],
                                    style: TextStyle(
                                      color: isDone ? Colors.grey : Colors.white,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: task['description'] != null && task['description'].isNotEmpty
                                      ? Text(
                                          task['description'],
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _priorityIcon(priority),
                                        color: _priorityColor(priority),
                                        size: 18,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        priority,
                                        style: TextStyle(
                                          color: _priorityColor(priority),
                                          fontSize: 10,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddTaskDialog,
          backgroundColor: const Color(0xFF7C6AF7),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('مهمة جديدة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
  }
}
