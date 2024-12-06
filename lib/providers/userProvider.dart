import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tunaskarsa/main.dart';
import 'package:tunaskarsa/pages/quizHomePage.dart';
import '../models/user.dart';
import 'dart:async'; //import timer

class UserProvider with ChangeNotifier {
  final List<User> _users = []; // Daftar semua user
  User? _loggedInUser; // User yang sedang login

  Timer? _timer; // Timer for screen time countdown
  String _screenTimeRemaining =
      "00:00"; // Remaining screen time in minutes, it always starts at 0 for default value
  DateTime?
      _screenTimeEndAt; // Berakhirnya screen time dalam bentuk datetime agar persistent meskipun logout gabakal reset ke nilai awal
  List<User> get users => _users;
  User? get loggedInUser => _loggedInUser;
  String get screenTimeRemaining =>
      _screenTimeRemaining; // Expose remaining screen time
  // String get formattedTime => formatTime;

  // Login user berdasarkan email dan password
  void login(String email, String password) {
    _loggedInUser = _users.firstWhere(
      (user) => user.email == email && user.password == password,
      orElse: () => throw Exception('User not found'),
    );
    _loggedInUser!.isLoggedIn = true;

    // Add initialization of screen time for child users
    if (_loggedInUser?.role == 'Anak') {
      _screenTimeRemaining =
          _loggedInUser?.screenTimeEndAt != null ? formatTime : "00:00";
      if (_screenTimeRemaining != "00:00") {
        startCountdown();
      }
    }

    notifyListeners();
  }

  // Logout user yang sedang login
  void logout() {
    if (_loggedInUser != null) {
      _loggedInUser!.isLoggedIn = false; // Reset status login
      _loggedInUser = null;
      stopCountdown(); // Stop countdown when user logs out
      notifyListeners();
    }
  }

  // Menambahkan user baru ke dalam sistem
  void registerUser(User user) {
    _users.add(user);
    notifyListeners();
  }

  void updateUser({required String username, required String email}) {
    if (loggedInUser != null) {
      _loggedInUser = loggedInUser!.copyWith(
        username: username,
        email: email,
      );
      notifyListeners();
    }
  }

  // Mendapatkan daftar anak untuk orang tua yang sedang login
  List<User> getChildrenForLoggedInUser() {
    if (_loggedInUser == null) return [];
    return _users
        .where((user) => user.role == 'Anak')
        .toList(); // Filter berdasarkan role "Anak"
  }

  // Mendapatkan daftar orang tua untuk anak yang sedang login
  List<User> getParentForLoggedInUser() {
    if (_loggedInUser == null) return [];
    return _users
        .where((user) => user.role == 'Orang Tua')
        .toList(); // Filter berdasarkan role "Orang Tua"
  }

  // Mendapatkan anak berdasarkan ID
  User? getChildById(String childId) {
    if (_loggedInUser == null || _loggedInUser!.role != 'Orang Tua') {
      return null; // Hanya orang tua yang bisa melihat anak
    }
    return _users.firstWhere(
      (user) => user.id == childId && user.role == 'Anak',
      orElse: () =>
          User(email: '', password: '', username: '', role: '', id: ''),
    );
  }

  // Menyimpan waktu layar untuk anak
  void saveScreenTime(String childId, int screenTimeInMinutes) {
    if (_loggedInUser == null || _loggedInUser!.role != 'Orang Tua') {
      return; // Hanya orang tua yang bisa mengatur screen time
    }

    final child = getChildById(childId); // Mendapatkan data anak berdasarkan ID
    if (child != null) {
      _screenTimeEndAt = DateTime.now().add(Duration(
          minutes:
              screenTimeInMinutes)); // Waktu sekarang ditambah dengan menit screen time
      // Update waktu layar anak
      final updatedChild = child.copyWith(
        screenTime: screenTimeInMinutes,
        username: child.username,
        email: child.email,
        screenTimeEndAt: _screenTimeEndAt,
      );
      // Update daftar user dengan data anak yang sudah diubah
      int index = _users.indexWhere((user) => user.id == child.id);
      if (index != -1) {
        _users[index] = updatedChild;

        if (_loggedInUser?.id == childId) {
          _screenTimeRemaining =
              formatTime; //Initialize countdown basically starting it
          stopCountdown(); // stop the countdown
          startCountdown(); // Start countdown for new screen time
        }
        notifyListeners(); // Notifikasi perubahan ke UI it'll change the ui basically
      }
    }
  }

  // Start the countdown timer
  void startCountdown() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_screenTimeRemaining != "00:00" && _screenTimeEndAt != null) {
        _screenTimeRemaining = formatTime;
        notifyListeners();
        print('Screen time remaining: $_screenTimeRemaining');
      } else {
        _timer?.cancel(); 
        redirectQuiz();
      }
    });
  }

  void redirectQuiz() {
    if (_screenTimeRemaining == "00:00") {
      Future.delayed(const Duration(milliseconds: 100), () {
        MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => QuizHomePage()),
        );
      });

      print('Aplikasi seharusnya terbuka sekarang');
    }
  }

  String get formatTime {
    if (_screenTimeEndAt != null) {
      final remaining = _screenTimeEndAt!.difference(DateTime
          .now()); // Sisa waktu dengan kalkulasi perbedaan waktu sekarang dan waktu berakhirnya screen time
      int minutes = remaining.inMinutes % 60;
      int seconds = remaining.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return "00:00";
  }

  // Stop the countdown timer
  void stopCountdown() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up timer when provider is disposed
    super.dispose();
  }

  void addTime(int reward) {
    _screenTimeEndAt!.add(Duration(minutes: reward));
    _screenTimeRemaining = formatTime;
    print('tambah');
    stopCountdown();
    startCountdown();
    notifyListeners();
    print('countdown');
  }
}