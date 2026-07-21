class InvolvedEntity {
  final String id;
  final String code;
  final String name;

  const InvolvedEntity({
    required this.id,
    required this.code,
    required this.name,
  });

  factory InvolvedEntity.fromJson(Map<String, dynamic> json) {
    return InvolvedEntity(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '-').toString(),
      name: (json['name'] ?? '-').toString(),
    );
  }
}

class ProjectClient {
  final String id;
  final String name;
  final String industry;
  final String phase;
  final String status;
  final String email;
  final String location;

  const ProjectClient({
    required this.id,
    required this.name,
    required this.industry,
    required this.phase,
    required this.status,
    this.email = '-',
    this.location = '-',
  });

  factory ProjectClient.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProjectClient(
        id: '',
        name: '-',
        industry: '-',
        phase: '-',
        status: '-',
      );
    }
    final industry = (json['industry'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final location = (json['location'] ?? '').toString();
    return ProjectClient(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '-').toString(),
      industry: industry.isEmpty ? '-' : industry,
      phase: (json['phase'] ?? '-').toString(),
      status: (json['status'] ?? '-').toString(),
      email: email.isEmpty ? '-' : email,
      location: location.isEmpty ? '-' : location,
    );
  }
}

class ProbabilityIndicator {
  final String code;
  final String title;
  final String value;
  final int contribution;

  const ProbabilityIndicator({
    required this.code,
    required this.title,
    required this.value,
    required this.contribution,
  });

  factory ProbabilityIndicator.fromJson(Map<String, dynamic> json) {
    return ProbabilityIndicator(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '-').toString(),
      value: (json['value'] ?? '-').toString(),
      contribution: (json['contribution'] is int)
          ? json['contribution'] as int
          : int.tryParse('${json['contribution']}') ?? 0,
    );
  }
}

class ProbabilityDetail {
  final int finalPercentage;
  final List<ProbabilityIndicator> indicators;

  const ProbabilityDetail({
    required this.finalPercentage,
    required this.indicators,
  });

  factory ProbabilityDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProbabilityDetail(finalPercentage: 0, indicators: []);
    }
    final rawIndicators = (json['indicators'] is List)
        ? json['indicators'] as List
        : const [];
    return ProbabilityDetail(
      finalPercentage: (json['finalPercentage'] is int)
          ? json['finalPercentage'] as int
          : int.tryParse('${json['finalPercentage']}') ?? 0,
      indicators: rawIndicators
          .map(
            (e) => ProbabilityIndicator.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class ProjectDetail {
  final String id;
  final String clientId;
  final String projectName;
  final String scopeOfWork;
  final num dealValue;
  final String createdBy;
  final String createdByEntity;
  final String createdAt;
  final List<InvolvedEntity> involvedEntity;
  final String opportunityType;
  final String salesStatus;
  final int probabilityPercentage;
  final String expectedStartDate;
  final String expectedEndDate;
  final String riskLevel;
  final String riskStatus;
  final ProjectClient client;
  final ProbabilityDetail probabilityDetail;

  const ProjectDetail({
    required this.id,
    required this.clientId,
    required this.projectName,
    required this.scopeOfWork,
    required this.dealValue,
    required this.createdBy,
    required this.createdByEntity,
    required this.createdAt,
    required this.involvedEntity,
    required this.opportunityType,
    required this.salesStatus,
    required this.probabilityPercentage,
    required this.expectedStartDate,
    required this.expectedEndDate,
    required this.riskLevel,
    required this.riskStatus,
    required this.client,
    required this.probabilityDetail,
  });

  String get scopeOfWorkLabel => scopeOfWork.trim().isEmpty ? '-' : scopeOfWork;

  String get involvedEntityLabel => involvedEntity.isEmpty
      ? '-'
      : involvedEntity.map((e) => e.code).join(', ');

  String get opportunityTypeLabel => opportunityType.trim().isEmpty
      ? '-'
      : opportunityType.replaceAll('-', ' ');

  String get expectedStartLabel =>
      expectedStartDate.trim().isEmpty ? '-' : expectedStartDate;

  String get expectedEndLabel =>
      expectedEndDate.trim().isEmpty ? '-' : expectedEndDate;

  String get formattedDealValue {
    final value = dealValue.round();
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    return 'Rp$buffer';
  }

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final rawEntities = (json['involvedEntity'] is List)
        ? json['involvedEntity'] as List
        : const [];
    return ProjectDetail(
      id: (json['id'] ?? '').toString(),
      clientId: (json['clientId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '-').toString(),
      scopeOfWork: (json['scopeOfWork'] ?? '').toString(),
      dealValue: (json['dealValue'] is num)
          ? json['dealValue'] as num
          : num.tryParse('${json['dealValue']}') ?? 0,
      createdBy: (json['createdBy'] ?? '-').toString(),
      createdByEntity: (json['createdByEntity'] ?? '-').toString(),
      createdAt: (json['createdAt'] ?? '-').toString(),
      involvedEntity: rawEntities
          .map(
            (e) => InvolvedEntity.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      opportunityType: (json['opportunityType'] ?? '').toString(),
      salesStatus: (json['salesStatus'] ?? '-').toString(),
      probabilityPercentage: (json['probabilityPercentage'] is int)
          ? json['probabilityPercentage'] as int
          : int.tryParse('${json['probabilityPercentage']}') ?? 0,
      expectedStartDate: (json['expectedStartDate'] ?? '').toString(),
      expectedEndDate: (json['expectedEndDate'] ?? '').toString(),
      riskLevel: (json['riskLevel'] ?? '-').toString(),
      riskStatus: (json['riskStatus'] ?? '-').toString(),
      client: ProjectClient.fromJson(json['client'] as Map<String, dynamic>?),
      probabilityDetail: ProbabilityDetail.fromJson(
        json['probabilityDetail'] as Map<String, dynamic>?,
      ),
    );
  }
}
