import 'package:equatable/equatable.dart';

class TenantInfo extends Equatable {
  final String code;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? slogan;
  final String? bannerUrl;

  const TenantInfo({
    required this.code,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.slogan,
    this.bannerUrl,
  });

  factory TenantInfo.fromLandingJson(String code, Map<String, dynamic> json) {
    final header = json['header'] as Map<String, dynamic>?;
    final theme = json['theme'] as Map<String, dynamic>?;
    final hero = json['hero'] as Map<String, dynamic>?;

    final title = hero?['title'] as String?;
    final slogan = header?['slogan'] as String?;

    return TenantInfo(
      code: code.trim().toLowerCase(),
      name: (title != null && title.isNotEmpty) ? title : code.toUpperCase(),
      logoUrl: header?['logoImageUrl'] as String?,
      primaryColor: theme?['primaryColor'] as String?,
      secondaryColor: theme?['secondaryColor'] as String?,
      slogan: slogan,
      bannerUrl: hero?['bannerImageUrl'] as String?,
    );
  }

  factory TenantInfo.fromJson(Map<String, dynamic> json) {
    return TenantInfo(
      code: json['code'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      slogan: json['slogan'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'slogan': slogan,
      'bannerUrl': bannerUrl,
    };
  }

  @override
  List<Object?> get props => [code, name, logoUrl, primaryColor, secondaryColor, slogan, bannerUrl];
}
