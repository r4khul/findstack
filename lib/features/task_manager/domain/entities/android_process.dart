/// Data model representing an Android process.
///
/// This entity captures information about a running process on the device,
/// including its resource usage and state.
library;

/// Represents a single Android process with system information.
///
/// Process data is typically obtained from native code parsing `/proc`
/// or using shell commands like `top` or `ps`.
///
/// ## Fields
/// - [pid]: Process ID (unique identifier)
/// - [user]: Linux user running the process (e.g., "root", "system")
/// - [name]: Process name or executable path
/// - [cpu]: CPU usage percentage as a string
/// - [mem]: Memory usage percentage as a string
/// - [res]: Resident Set Size (actual memory in use)
/// - [vsz]: Virtual memory size
/// - [status]: Process status (S=sleeping, R=running, etc.)
///
/// ## Example
/// ```dart
/// final process = AndroidProcess(
///   pid: "1234",
///   user: "system",
///   name: "com.android.systemui",
///   cpu: "2.5",
///   mem: "1.2",
///   res: "45M",
/// );
/// ```
class AndroidProcess {
  /// The process ID (unique within the system).
  final String pid;

  /// The Linux user running this process.
  ///
  /// Common values: "root", "system", "u0_a123" (app user).
  final String user;

  /// The process name or command.
  ///
  /// For apps, this typically contains the package name.
  final String name;

  /// CPU usage percentage.
  ///
  /// Expressed as a string (e.g., "2.5" for 2.5%).
  final String cpu;

  /// Memory usage percentage.
  final String mem;

  /// Resident Set Size - actual physical memory used.
  ///
  /// Typically expressed with unit suffix (e.g., "45M").
  final String res;

  /// Virtual memory size.
  final String vsz;

  /// Process state/status.
  ///
  /// Common values:
  /// - S: Sleeping
  /// - R: Running
  /// - D: Uninterruptible sleep
  /// - Z: Zombie
  final String status;

  /// Creates an Android process instance.
  const AndroidProcess({
    required this.pid,
    required this.user,
    required this.name,
    this.cpu = "0.0",
    this.mem = "0.0",
    this.res = "0",
    this.vsz = "0",
    this.status = "S",
  });

  /// Creates an [AndroidProcess] from a native Map.
  ///
  /// Used when parsing data received from native Android code
  /// through platform channels.
  factory AndroidProcess.fromMap(Map<Object?, Object?> map) {
    return AndroidProcess(
      pid: map['pid']?.toString() ?? "?",
      user: map['user']?.toString() ?? "?",
      name: map['name']?.toString() ?? "Unknown",
      cpu: map['cpu']?.toString() ?? "0.0",
      mem: map['mem']?.toString() ?? "0.0",
      res: map['res']?.toString() ?? "0",
      vsz: map['vsz']?.toString() ?? "0",
      status: map['s']?.toString() ?? "S",
    );
  }
}
