class ClientModel {
  final String id;
  final String companyName;
  final String phase;
  final String clientStatus;
  final String clientType;
  final String industry;
  final String picName;
  final double percentage;
  final int daysInPhase;

  ClientModel({
    required this.id,
    required this.companyName,
    required this.phase,
    required this.clientStatus,
    required this.clientType,
    required this.industry,
    required this.picName,
    required this.percentage,
    required this.daysInPhase,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: (json['id'] ?? '').toString(),
      companyName: (json['companyName'] ?? '-').toString(),
      phase: (json['phase'] ?? '-').toString(),
      clientStatus: (json['clientStatus'] ?? '-').toString(),
      clientType: (json['clientType'] ?? '-').toString(),
      industry:
          (json['industry']?.toString().isNotEmpty == true
                  ? json['industry']
                  : '-')
              .toString(),
      picName:
          (json['picName']?.toString().isNotEmpty == true
                  ? json['picName']
                  : '-')
              .toString(),
      percentage: json['percentage'] is num
          ? (json['percentage'] as num).toDouble()
          : 0,
      daysInPhase: json['daysInPhase'] is num
          ? (json['daysInPhase'] as num).toInt()
          : 0,
    );
  }
}

class ClientListResult {
  final List<ClientModel> clients;
  final int totalRows;

  const ClientListResult({required this.clients, required this.totalRows});
}

class ClientPhaseSummary {
  final int? leads;
  final int? account;
  final int? stages;

  const ClientPhaseSummary({this.leads, this.account, this.stages});
}
