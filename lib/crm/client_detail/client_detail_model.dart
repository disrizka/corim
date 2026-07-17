class ClientDetailModel {
  final String id;
  final String companyName;
  final String clientType;
  final String entityCode;
  final String industry;
  final String clientStatus;
  final String phase;
  final String address;
  final String email;
  final String phoneNumber;
  final List<PicModel> pics;
  final HealthPointsDetail? healthPointsDetail;

  ClientDetailModel({
    required this.id,
    required this.companyName,
    required this.clientType,
    required this.entityCode,
    required this.industry,
    required this.clientStatus,
    required this.phase,
    required this.address,
    required this.email,
    required this.phoneNumber,
    required this.pics,
    required this.healthPointsDetail,
  });

  factory ClientDetailModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailModel(
      id: json['id'] ?? '',
      companyName: json['companyName'] ?? '-',
      clientType: json['clientType'] ?? '-',
      entityCode: json['entityCode'] ?? '-',
      industry: json['industry'] ?? '-',
      clientStatus: json['clientStatus'] ?? '-',
      phase: json['phase'] ?? '-',
      address: json['address'] ?? '-',
      email: json['email'] ?? '-',
      phoneNumber: json['phoneNumber'] ?? '-',
      pics: (json['pics'] as List? ?? [])
          .map((e) => PicModel.fromJson(e))
          .toList(),
      healthPointsDetail: json['healthPointsDetail'] != null
          ? HealthPointsDetail.fromJson(json['healthPointsDetail'])
          : null,
    );
  }
}

class PicModel {
  final String id;
  final String picName;
  final String emailPic;
  final String picPhoneNumber;

  PicModel({
    required this.id,
    required this.picName,
    required this.emailPic,
    required this.picPhoneNumber,
  });

  factory PicModel.fromJson(Map<String, dynamic> json) {
    return PicModel(
      id: json['id'] ?? '',
      picName: json['picName'] ?? '-',
      emailPic: json['emailPic'] ?? '-',
      picPhoneNumber: json['picPhoneNumber'] ?? '-',
    );
  }
}

class HealthPointsDetail {
  final int finalScore;
  final String label;
  final double percentage;

  HealthPointsDetail({
    required this.finalScore,
    required this.label,
    required this.percentage,
  });

  factory HealthPointsDetail.fromJson(Map<String, dynamic> json) {
    return HealthPointsDetail(
      finalScore: json['finalScore'] ?? 0,
      label: json['label'] ?? '-',
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}
