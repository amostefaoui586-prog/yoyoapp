import '../sql/database_helper.dart';

/// TaskController — طبقة المنطق بين الواجهة وقاعدة البيانات
/// كل العمليات تمر من هنا: تحقق من المدخلات، تجهيز البيانات، ثم الاتصال بـ DB
class TaskController {
  final DatabaseHelper _db = DatabaseHelper();

  // ─────────────────────────────────────────
  //  إضافة مهمة
  // ─────────────────────────────────────────

  /// إضافة مهمة جديدة بعد التحقق من صحة البيانات
  /// يُعيد id المهمة المُضافة، أو -1 في حال الفشل
  Future<int> addTask({
    required String title,
    String description = '',
    String priority = 'متوسط',
  }) async {
    // ── تحقق من المدخلات ──
    final validation = _validateTask(title: title, priority: priority);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    final task = {
      'title':       title.trim(),
      'description': description.trim(),
      'priority':    priority,
      'is_done':     0,
      'created_at':  DateTime.now().toIso8601String(),
    };

    return await _db.insertTask(task);
  }

  // ─────────────────────────────────────────
  //  جلب المهام
  // ─────────────────────────────────────────

  /// جلب جميع المهام
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    return await _db.fetchAllTasks();
  }

  /// جلب المهام غير المكتملة فقط
  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    return await _db.fetchTasksByStatus(false);
  }

  /// جلب المهام المكتملة فقط
  Future<List<Map<String, dynamic>>> getCompletedTasks() async {
    return await _db.fetchTasksByStatus(true);
  }

  /// جلب مهمة بالمعرّف
  Future<Map<String, dynamic>?> getTaskById(int id) async {
    if (id <= 0) throw Exception('معرّف المهمة غير صالح');
    return await _db.fetchTaskById(id);
  }

  /// جلب المهام حسب الأولوية
  Future<List<Map<String, dynamic>>> getTasksByPriority(String priority) async {
    if (!_validPriorities.contains(priority)) {
      throw Exception('قيمة الأولوية غير صالحة: $priority');
    }
    return await _db.fetchTasksByPriority(priority);
  }

  // ─────────────────────────────────────────
  //  تحديث مهمة
  // ─────────────────────────────────────────

  /// تحديث عنوان أو وصف أو أولوية مهمة موجودة
  Future<bool> updateTask({
    required int id,
    String? title,
    String? description,
    String? priority,
  }) async {
    if (id <= 0) throw Exception('معرّف المهمة غير صالح');

    final values = <String, dynamic>{};

    if (title != null) {
      final v = _validateTask(title: title, priority: priority ?? 'متوسط');
      if (!v.isValid) throw Exception(v.errorMessage);
      values['title'] = title.trim();
    }

    if (description != null) values['description'] = description.trim();

    if (priority != null) {
      if (!_validPriorities.contains(priority)) {
        throw Exception('قيمة الأولوية غير صالحة');
      }
      values['priority'] = priority;
    }

    if (values.isEmpty) return false;

    final rowsAffected = await _db.updateTask(id, values);
    return rowsAffected > 0;
  }

  /// تبديل حالة إنجاز المهمة (مكتملة ↔ غير مكتملة)
  Future<bool> toggleTask(int id, bool currentIsDone) async {
    if (id <= 0) throw Exception('معرّف المهمة غير صالح');
    final rowsAffected = await _db.toggleTaskDone(id, currentIsDone);
    return rowsAffected > 0;
  }

  // ─────────────────────────────────────────
  //  حذف مهمة
  // ─────────────────────────────────────────

  /// حذف مهمة بالمعرّف
  Future<bool> deleteTask(int id) async {
    if (id <= 0) throw Exception('معرّف المهمة غير صالح');
    final rowsAffected = await _db.deleteTask(id);
    return rowsAffected > 0;
  }

  /// حذف جميع المهام المكتملة (تنظيف)
  Future<int> clearCompletedTasks() async {
    return await _db.deleteCompletedTasks();
  }

  // ─────────────────────────────────────────
  //  إحصائيات
  // ─────────────────────────────────────────

  /// جلب إحصائيات المهام: الكل / المكتملة / قيد التنفيذ
  Future<Map<String, int>> getStats() async {
    return await _db.getTaskStats();
  }

  /// حساب نسبة الإنجاز (0.0 → 1.0)
  Future<double> getCompletionRate() async {
    final stats = await getStats();
    final total = stats['total'] ?? 0;
    if (total == 0) return 0.0;
    final done = stats['done'] ?? 0;
    return done / total;
  }

  // ─────────────────────────────────────────
  //  مساعدات داخلية
  // ─────────────────────────────────────────

  static const List<String> _validPriorities = ['منخفض', 'متوسط', 'عالي'];

  _ValidationResult _validateTask({
    required String title,
    required String priority,
  }) {
    if (title.trim().isEmpty) {
      return _ValidationResult(false, 'عنوان المهمة لا يمكن أن يكون فارغاً');
    }
    if (title.trim().length > 200) {
      return _ValidationResult(false, 'عنوان المهمة طويل جداً (الحد الأقصى 200 حرف)');
    }
    if (!_validPriorities.contains(priority)) {
      return _ValidationResult(false, 'الأولوية يجب أن تكون: منخفض، متوسط، أو عالي');
    }
    return _ValidationResult(true, '');
  }
}

/// نتيجة التحقق من صحة البيانات
class _ValidationResult {
  final bool isValid;
  final String errorMessage;
  const _ValidationResult(this.isValid, this.errorMessage);
}
