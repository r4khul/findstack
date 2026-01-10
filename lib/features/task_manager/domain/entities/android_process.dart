library;

class AndroidProcess {
  final String pid;

  final String user;

  final String name;

  final String cpu;

  final String mem;

  final String res;

  final String vsz;

  final String status;

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
