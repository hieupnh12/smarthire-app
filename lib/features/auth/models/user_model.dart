import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String workspace;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.workspace,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'CANDIDATE',
      workspace: json['workspace'] as String? ?? 'CANDIDATE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'workspace': workspace,
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, phone, avatarUrl, role, workspace];
}
