/// Customizable presentation configuration for PDF financial statement exports.
class PdfReportConfig {
  const PdfReportConfig({
    this.title = 'Personal Financial Report',
    this.subtitle,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.footerText = 'Confidential • Personal Financial Statement',
    this.logoPath,
  });

  /// Main document header title.
  final String title;

  /// Optional secondary subtitle (e.g. "Monthly Statement - September 2026").
  final String? subtitle;

  /// User or business entity name.
  final String? name;

  /// Contact phone number.
  final String? phone;

  /// Contact email address.
  final String? email;

  /// Physical or business address.
  final String? address;

  /// Bottom footer text printed on all pages.
  final String footerText;

  /// Local file path or asset URI to optional custom logo image.
  final String? logoPath;

  PdfReportConfig copyWith({
    String? title,
    String? subtitle,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? footerText,
    String? logoPath,
  }) {
    return PdfReportConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      footerText: footerText ?? this.footerText,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfReportConfig &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subtitle == other.subtitle &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          footerText == other.footerText &&
          logoPath == other.logoPath;

  @override
  int get hashCode =>
      title.hashCode ^
      subtitle.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode ^
      footerText.hashCode ^
      logoPath.hashCode;
}
