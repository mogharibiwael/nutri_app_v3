class AdModel {
  final int id;
  final String? title;
  final String? imageUrl;
  final String? link;
  final String? description;
  final String? phoneNumber;
  final String? type;
  final bool isActive;

  AdModel({
    required this.id,
    this.title,
    this.imageUrl,
    this.link,
    this.description,
    this.phoneNumber,
    this.type,
    this.isActive = true,
  });

  factory AdModel.fromJson(Map<String, dynamic> json, {String? storageBase}) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    String? rawImage = (json["image_url"] ?? json["image"])?.toString();
    String? imageUrl = rawImage;

    String _normalizeUrl(String url) {
      // Many backends return "http://" URLs; on Android this can fail due to cleartext policy.
      // Prefer https when possible.
      if (url.startsWith("http://")) return "https://${url.substring("http://".length)}";
      return url;
    }

    if (imageUrl != null) {
      imageUrl = imageUrl.trim();
      if (imageUrl.isEmpty) {
        imageUrl = null;
      } else {
        // Remove leading slash before joining with base.
        if (imageUrl.startsWith("/")) imageUrl = imageUrl.substring(1);
        if (storageBase != null && storageBase.isNotEmpty && !imageUrl.startsWith("http")) {
          final base = storageBase.endsWith("/") ? storageBase : "$storageBase/";
          imageUrl = "$base$imageUrl";
        }
        imageUrl = _normalizeUrl(imageUrl);
      }
    }

    return AdModel(
      id: _toInt(json["id"]),
      title: json["title"]?.toString(),
      imageUrl: imageUrl ?? rawImage,
      link: json["link"]?.toString(),
      description: json["description"]?.toString() ?? json["describtion"]?.toString(),
      phoneNumber: json["phone_number"]?.toString(),
      type: json["type"]?.toString(),
      isActive: json["is_active"] == true || json["is_active"] == 1 || json["is_active"] == "1",
    );
  }
}
