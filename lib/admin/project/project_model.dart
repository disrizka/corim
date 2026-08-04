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

class ProjectPic {
  final String id;
  final String picName;
  final String picPhoneNumber;
  final String emailPic;
  final String gender;
  final String ageRange;
  final String decisionMaker;
  final String relationLevel;
  final String jabatan;
  final String divisi;

  const ProjectPic({
    required this.id,
    required this.picName,
    this.picPhoneNumber = '-',
    this.emailPic = '-',
    this.gender = '-',
    this.ageRange = '-',
    this.decisionMaker = '-',
    this.relationLevel = '-',
    this.jabatan = '-',
    this.divisi = '-',
  });

  factory ProjectPic.fromJson(Map<String, dynamic> json) {
    String field(String key) {
      final v = (json[key] ?? '').toString();
      return v.isEmpty ? '-' : v;
    }

    return ProjectPic(
      id: (json['id'] ?? '').toString(),
      picName: field('picName'),
      picPhoneNumber: field('picPhoneNumber'),
      emailPic: field('emailPic'),
      gender: field('gender'),
      ageRange: field('ageRange'),
      decisionMaker: field('decisionMaker'),
      relationLevel: field('relationLevel'),
      jabatan: field('jabatan'),
      divisi: field('divisi'),
    );
  }
}

class ProjectService {
  final String id;
  final String entityId;
  final String entityCode;
  final String entityName;
  final String serviceName;

  const ProjectService({
    required this.id,
    required this.entityId,
    required this.entityCode,
    required this.entityName,
    required this.serviceName,
  });

  factory ProjectService.fromJson(Map<String, dynamic> json) {
    return ProjectService(
      id: (json['id'] ?? '').toString(),
      entityId: (json['entityId'] ?? '').toString(),
      entityCode: (json['entityCode'] ?? '-').toString(),
      entityName: (json['entityName'] ?? '-').toString(),
      serviceName: (json['serviceName'] ?? '-').toString(),
    );
  }
}

class ProjectSubService {
  final String id;
  final String serviceId;
  final String serviceName;
  final String subServiceName;

  const ProjectSubService({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.subServiceName,
  });

  factory ProjectSubService.fromJson(Map<String, dynamic> json) {
    return ProjectSubService(
      id: (json['id'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? '-').toString(),
      subServiceName: (json['subServiceName'] ?? '-').toString(),
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
    final phase = (json['phase'] ?? '').toString();
    return ProjectClient(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '-').toString(),
      industry: industry.isEmpty ? '-' : industry,
      phase: phase.isEmpty ? '-' : phase,
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

String formatRupiah(num value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return 'Rp $buffer';
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
  final List<ProjectPic> pics;
  final List<ProjectService> services;
  final List<ProjectSubService> subServices;
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
    required this.pics,
    required this.services,
    required this.subServices,
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

  String get picLabel =>
      pics.isEmpty ? '-' : pics.map((e) => e.picName).join(', ');

  String get serviceLabel => services.isEmpty
      ? '-'
      : services.map((s) => '[${s.entityCode}] ${s.serviceName}').join(' ');

  String get subServiceLabel => subServices.isEmpty
      ? '-'
      : subServices
            .map((s) => '${s.serviceName} - ${s.subServiceName}')
            .join(', ');

  String get probabilityStatusLabel =>
      '$probabilityPercentage%( $salesStatus )';

  String get formattedDealValue => formatRupiah(dealValue);

  num get weightValue => dealValue * probabilityPercentage / 100;

  String get formattedWeightValue => formatRupiah(weightValue);

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final rawEntities = (json['involvedEntity'] is List)
        ? json['involvedEntity'] as List
        : const [];
    final rawPics = (json['pics'] is List) ? json['pics'] as List : const [];
    final rawServices = (json['services'] is List)
        ? json['services'] as List
        : const [];
    final rawSubServices = (json['subServices'] is List)
        ? json['subServices'] as List
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
      pics: rawPics
          .map((e) => ProjectPic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      services: rawServices
          .map(
            (e) => ProjectService.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      subServices: rawSubServices
          .map(
            (e) =>
                ProjectSubService.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      probabilityDetail: ProbabilityDetail.fromJson(
        json['probabilityDetail'] as Map<String, dynamic>?,
      ),
    );
  }
}

class SalesStatusEvent {
  final String id;
  final String category;
  final String title;
  final String description;
  final String createdByName;
  final DateTime? createdAt;
  final String createdAtLabel;
  final num? value;
  final String? expectedStartDate;
  final String? expectedEndDate;
  final String? signedAtLabel;
  final String? quotationNumber;
  final String status;

  const SalesStatusEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.createdByName,
    required this.createdAt,
    required this.createdAtLabel,
    required this.value,
    required this.expectedStartDate,
    required this.expectedEndDate,
    required this.signedAtLabel,
    required this.quotationNumber,
    required this.status,
  });

  bool get isQuotation => category == 'quotations';

  bool get isSigned => (signedAtLabel ?? '').trim().isNotEmpty;

  String get formattedValue => value == null ? '-' : formatRupiah(value!);

  String get expectedRangeLabel {
    final s = (expectedStartDate ?? '').trim();
    final e = (expectedEndDate ?? '').trim();
    if (s.isEmpty && e.isEmpty) return '-';
    return '${s.isEmpty ? '-' : s} - ${e.isEmpty ? '-' : e}';
  }

  factory SalesStatusEvent.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? '').toString();

    if (category == 'quotations') {
      final status = (json['status'] ?? '-').toString();
      final signedAt = (json['signedAt'] ?? '').toString();
      final isSigned = status.toLowerCase() == 'signed' && signedAt.isNotEmpty;

      return SalesStatusEvent(
        id: (json['id'] ?? '').toString(),
        category: category,
        title: 'Quotation: ${(json['quotationNumber'] ?? '-').toString()}',
        description: '',
        createdByName: (json['createdByName'] ?? '-').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
        createdAtLabel: (json['createdAt'] ?? '-').toString(),
        value: (json['quotationValue'] is num)
            ? json['quotationValue'] as num
            : num.tryParse('${json['quotationValue']}'),
        expectedStartDate: (json['expectedStartDate'] ?? '').toString(),
        expectedEndDate: (json['expectedEndDate'] ?? '').toString(),
        signedAtLabel: isSigned ? signedAt : null,
        quotationNumber: (json['quotationNumber'] ?? '-').toString(),
        status: status,
      );
    }

    final desc = (json['desc'] ?? json['activityDesc'] ?? '').toString();
    return SalesStatusEvent(
      id: (json['id'] ?? '').toString(),
      category: category.isEmpty ? 'activity' : category,
      title: (json['title'] ?? '-').toString(),
      description: desc,
      createdByName: (json['createdByName'] ?? '-').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      createdAtLabel: (json['activityDate'] ?? json['createdAt'] ?? '-')
          .toString(),
      value: null,
      expectedStartDate: null,
      expectedEndDate: null,
      signedAtLabel: null,
      quotationNumber: null,
      status: (json['salesStatus'] ?? json['approvalStatus'] ?? '-').toString(),
    );
  }
}

class DeliveryStatusEvent {
  final String id;
  final String title;
  final String description;
  final String createdByName;
  final String createdAtLabel;
  final String status;

  const DeliveryStatusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.createdByName,
    required this.createdAtLabel,
    required this.status,
  });

  factory DeliveryStatusEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['deliveryTitle'] ?? '-').toString(),
      description: (json['desc'] ?? json['description'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '-').toString(),
      createdAtLabel: (json['activityDate'] ?? json['createdAt'] ?? '-')
          .toString(),
      status: (json['status'] ?? json['deliveryStatus'] ?? '-').toString(),
    );
  }
}
