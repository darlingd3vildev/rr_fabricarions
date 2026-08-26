import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rr_fabrication/models/attendance_model.dart';
import 'package:rr_fabrication/models/user_model.dart';
import 'package:rr_fabrication/models/user_role.dart';
import 'package:rr_fabrication/screens/common/app_drawer.dart';
import 'package:rr_fabrication/services/attendance_service.dart';
import 'package:rr_fabrication/services/auth_service.dart';
import 'package:rr_fabrication/services/storage_service.dart';

class AttendanceScreen extends StatefulWidget {
  final UserRole userRole;

  const AttendanceScreen({
    super.key,
    this.userRole = UserRole.ATTENDANCE,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  final TextEditingController _idInputController = TextEditingController();

  UserModel? _selectedEmployee;
  AttendanceModel? _todayAttendance;
  bool _isLoadingEmployee = false;

  XFile? _capturedPhotoFile;
  Uint8List? _capturedPhotoBytes;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idInputController.dispose();
    super.dispose();
  }

  Future<void> _lookupEmployee([String? query]) async {
    final q = query ?? _idInputController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoadingEmployee = true;
      _selectedEmployee = null;
      _todayAttendance = null;
      _capturedPhotoFile = null;
      _capturedPhotoBytes = null;
    });

    try {
      final results = await _attendanceService.searchEmployees(q);
      if (results.isNotEmpty) {
        final emp = results.first;
        final att =
            await _attendanceService.getEmployeeAttendanceToday(emp.id);
        setState(() {
          _selectedEmployee = emp;
          _todayAttendance = att;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No employee found for "$q"'),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error looking up employee: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEmployee = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _storageService.pickImageFromCamera();
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _capturedPhotoFile = file;
          _capturedPhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_selectedEmployee == null) return;

    setState(() => _isProcessingAction = true);

    try {
      final user = _authService.getCurrentUser();
      final recorderId = user?.uid ?? 'kiosk';

      await _attendanceService.recordCheckIn(
        employee: _selectedEmployee!,
        photoFile: _capturedPhotoFile,
        recordedByUserId: recorderId,
      );

      final updatedAtt = await _attendanceService
          .getEmployeeAttendanceToday(_selectedEmployee!.id);

      if (mounted) {
        setState(() {
          _todayAttendance = updatedAtt;
        });
        _showSuccessDialog(
          title: 'Checked In Successfully!',
          message:
              '${_selectedEmployee!.name} checked in for today at ${_formatTime(DateTime.now())}.',
          isCheckIn: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _confirmCheckOut() async {
    if (_selectedEmployee == null) return;

    setState(() => _isProcessingAction = true);

    try {
      final user = _authService.getCurrentUser();
      final recorderId = user?.uid ?? 'kiosk';

      await _attendanceService.recordCheckOut(
        employee: _selectedEmployee!,
        photoFile: _capturedPhotoFile,
        recordedByUserId: recorderId,
      );

      final updatedAtt = await _attendanceService
          .getEmployeeAttendanceToday(_selectedEmployee!.id);

      if (mounted) {
        setState(() {
          _todayAttendance = updatedAtt;
        });
        _showSuccessDialog(
          title: 'Checked Out Successfully!',
          message:
              '${_selectedEmployee!.name} checked out at ${_formatTime(DateTime.now())}.',
          isCheckIn: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-out failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  void _resetForNextEmployee() {
    setState(() {
      _selectedEmployee = null;
      _todayAttendance = null;
      _capturedPhotoFile = null;
      _capturedPhotoBytes = null;
      _idInputController.clear();
    });
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required bool isCheckIn,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isCheckIn ? Icons.check_circle : Icons.logout,
                color: isCheckIn ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
              if (_capturedPhotoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _capturedPhotoBytes!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resetForNextEmployee();
              },
              child: const Text('Next Employee'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentItem: DrawerItem.attendance,
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        title: const Text('Attendance Kiosk'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.touch_app), text: 'Check-In / Out'),
            Tab(icon: Icon(Icons.list_alt), text: "Today's Roster"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckInOutTab(),
          _buildTodayRosterTab(),
        ],
      ),
    );
  }

  Widget _buildCheckInOutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Input Field Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1: Identify Employee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idInputController,
                          decoration: InputDecoration(
                            labelText: 'Employee ID or Phone Number',
                            hintText: 'e.g. EMP001 or 9876543210',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onSubmitted: (val) => _lookupEmployee(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoadingEmployee ? null : () => _lookupEmployee(),
                        icon: _isLoadingEmployee
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: const Text('Retrieve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step 2 & 3: Display Employee Data & Take Photo
          if (_selectedEmployee != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          child: Text(
                            _selectedEmployee!.name.isNotEmpty
                                ? _selectedEmployee!.name[0].toUpperCase()
                                : 'E',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEmployee!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Role: ${_selectedEmployee!.role.displayName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedEmployee!.phoneNumber != null)
                                Text(
                                  'Phone: ${_selectedEmployee!.phoneNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Today's Status Banner
                    _buildTodayStatusBadge(),
                    const SizedBox(height: 20),

                    // Step 3: Photo Verification
                    const Text(
                      'Step 2: Verification Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_capturedPhotoBytes != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _capturedPhotoBytes!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Photo Captured',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    onPressed: _takePhoto,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retake Photo'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Verification Photo'),
                      ),

                    const SizedBox(height: 24),

                    // Step 4: Confirm Buttons
                    Row(
                      children: [
                        // Check In Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isProcessingAction ||
                                    (_todayAttendance?.isCheckedIn == true)
                                ? null
                                : _confirmCheckIn,
                            icon: const Icon(Icons.login),
                            label: const Text(
                              'Confirm Check-In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Check Out Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isProcessingAction ||
                                    (_todayAttendance?.isCheckedIn != true) ||
                                    (_todayAttendance?.isCheckedOut == true)
                                ? null
                                : _confirmCheckOut,
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Confirm Check-Out',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayStatusBadge() {
    if (_todayAttendance == null || !_todayAttendance!.isCheckedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text(
              'Status Today: Not Checked In Yet',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_todayAttendance!.isCheckedIn && !_todayAttendance!.isCheckedOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status: Checked In at ${_formatTime(_todayAttendance!.checkInTime!)} (Currently Active)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.done_all, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status: Day Completed (In: ${_formatTime(_todayAttendance!.checkInTime!)}, Out: ${_formatTime(_todayAttendance!.checkOutTime!)})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRosterTab() {
    return StreamBuilder<List<AttendanceModel>>(
      stream: _attendanceService.getTodayAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'No attendance entries recorded today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Employees checking in on the kiosk will appear here.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final att = list[index];
            final isOut = att.isCheckedOut;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    if (att.checkInPhotoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          att.checkInPhotoUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(att.userName.isNotEmpty
                                ? att.userName[0]
                                : 'U'),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        child: Text(
                          att.userName.isNotEmpty ? att.userName[0] : 'U',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            att.checkInTime != null
                                ? 'Check-In: ${_formatTime(att.checkInTime!)}'
                                : 'Check-In: --',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (att.checkOutTime != null)
                            Text(
                              'Check-Out: ${_formatTime(att.checkOutTime!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOut ? Colors.blue[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOut ? 'Checked Out' : 'Active (Present)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOut ? Colors.blue[800] : Colors.green[800],
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
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
