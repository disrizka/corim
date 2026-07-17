class ProjectListItem {
  final String id;
  final String clientName;
  final String projectName;
  final List<InvolvedEntity> involvedEntity;
  final int probabilityPercentage;
  final String opportunityType;
  final num dealValue;
  final String expectedStartDate;
  final String expectedEndDate;
  final String projectStatus;
  final String salesStatus;
  final String createdBy;

  ProjectListItem({
    required this.id,
    required this.clientName,
    required this.projectName,
    required this.involvedEntity,
    required this.probabilityPercentage,
    required this.opportunityType,
    required this.dealValue,
    required this.expectedStartDate,
    required this.expectedEndDate,
    required this.projectStatus,
    required this.salesStatus,
    required this.createdBy,
  });

  factory ProjectListItem.fromJson(Map<String, dynamic> json) {
    return ProjectListItem(
      id: json['id'] ?? '',
      clientName: json['clientName'] ?? '-',
      projectName: json['projectName'] ?? '-',
      involvedEntity: (json['involvedEntity'] as List? ?? [])
          .map((e) => InvolvedEntity.fromJson(e))
          .toList(),
      probabilityPercentage: json['probabilityPercentage'] ?? 0,
      opportunityType: json['opportunityType'] ?? '-',
      dealValue: json['dealValue'] ?? 0,
      expectedStartDate: json['expectedStartDate'] ?? '-',
      expectedEndDate: json['expectedEndDate'] ?? '-',
      projectStatus: json['projectStatus'] ?? '-',
      salesStatus: json['salesStatus'] ?? '-',
      createdBy: json['createdBy'] ?? '-',
    );
  }
}

class InvolvedEntity {
  final String id;
  final String code;
  final String name;

  InvolvedEntity({required this.id, required this.code, required this.name});

  factory InvolvedEntity.fromJson(Map<String, dynamic> json) {
    return InvolvedEntity(
      id: json['id'] ?? '',
      code: json['code'] ?? '-',
      name: json['name'] ?? '-',
    );
  }
}
