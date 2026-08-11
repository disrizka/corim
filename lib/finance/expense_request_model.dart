String formatRupiahExpense(num value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return '${isNegative ? '-' : ''}Rp $buffer';
}

String expenseFormTypeLabel(String formType) {
  switch (formType.toUpperCase()) {
    case 'PRF':
      return 'PRF';
    case 'STB':
      return 'STB';
    case 'SRF':
      return 'SRF';
    case 'SSR':
      return 'SSR';
    default:
      return formType;
  }
}

String expenseTitleCase(String value) {
  final normalized = value.replaceAll('_', ' ').toLowerCase();
  if (normalized.trim().isEmpty) return '-';
  return normalized
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class ExpenseRequestItem {
  final String id;
  final num amount;
  final bool canResubmit;
  final String createdAt;
  final String createdBy;
  final ExpenseEntityRef entity;
  final String formType;
  final List<ExpenseHistoryEntry> history;
  final String invoiceDate;
  final String notes;
  final String requestNumber;
  final int revisionCount;
  final String status;

  const ExpenseRequestItem({
    required this.id,
    required this.amount,
    required this.canResubmit,
    required this.createdAt,
    required this.createdBy,
    required this.entity,
    required this.formType,
    required this.history,
    required this.invoiceDate,
    required this.notes,
    required this.requestNumber,
    required this.revisionCount,
    required this.status,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  String get formattedAmount => formatRupiahExpense(amount);
  String get createdDatePart =>
      createdAt.contains(' ') ? createdAt.split(' ').first : createdAt;
  String get createdTimePart {
    if (!createdAt.contains(' ')) return '';
    final time = createdAt.split(' ').last;
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  factory ExpenseRequestItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = (json['history'] is List)
        ? json['history'] as List
        : const [];
    return ExpenseRequestItem(
      id: (json['id'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? json['amount'] as num
          : num.tryParse('${json['amount']}') ?? 0,
      canResubmit: json['canResubmit'] == true,
      createdAt: (json['createdAt'] ?? '-').toString(),
      createdBy: (json['createdBy'] ?? '-').toString(),
      entity: ExpenseEntityRef.fromJson(json['entity']),
      formType: (json['formType'] ?? '-').toString(),
      history: rawHistory
          .map(
            (e) => ExpenseHistoryEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      invoiceDate: (json['invoiceDate'] ?? '').toString(),
      notes: (json['notes'] ?? '-').toString(),
      requestNumber: (json['requestNumber'] ?? '-').toString(),
      revisionCount: (json['revisionCount'] is num)
          ? (json['revisionCount'] as num).toInt()
          : int.tryParse('${json['revisionCount']}') ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
    );
  }
}

class ExpenseHistoryEntry {
  final String createdAt;
  final String createdByName;
  final String formNumber;
  final String id;
  final String notes;

  const ExpenseHistoryEntry({
    required this.createdAt,
    required this.createdByName,
    required this.formNumber,
    required this.id,
    required this.notes,
  });

  factory ExpenseHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseHistoryEntry(
      createdAt: (json['createdAt'] ?? '-').toString(),
      createdByName: (json['createdByName'] ?? '-').toString(),
      formNumber: (json['formNumber'] ?? '-').toString(),
      id: (json['id'] ?? '').toString(),
      notes: (json['notes'] ?? '-').toString(),
    );
  }
}

class ExpenseNamedRef {
  final String id;
  final String name;

  const ExpenseNamedRef({required this.id, required this.name});

  factory ExpenseNamedRef.fromJson(dynamic json) {
    // Backend kadang mengirim relasi ini sebagai object hasil populate
    // ({"id": "...", "name": "..."}), tapi kadang cuma sebagai ID mentah
    // (String) saat endpoint yang bersangkutan tidak melakukan populate.
    // Kalau ini tidak ditangani, id jadi kebaca kosong walau sebenarnya
    // request tetap punya project, sehingga tombol "Open Project" gagal
    // secara tidak konsisten.
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return ExpenseNamedRef(
        id: (map['id'] ?? map['_id'] ?? '').toString(),
        name: (map['name'] ?? '-').toString(),
      );
    }
    if (json is String && json.trim().isNotEmpty) {
      // Hanya berupa ID mentah (belum di-populate oleh backend).
      // Tetap simpan id-nya supaya "Open Project" bisa jalan,
      // meski nama project belum bisa ditampilkan di sini.
      return ExpenseNamedRef(id: json.trim(), name: '-');
    }
    return const ExpenseNamedRef(id: '', name: '-');
  }
}

class ExpenseEntityRef {
  final String id;
  final String code;
  final String name;

  const ExpenseEntityRef({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ExpenseEntityRef.fromJson(dynamic json) {
    if (json is! Map)
      return const ExpenseEntityRef(id: '', code: '-', name: '-');
    final map = Map<String, dynamic>.from(json);
    return ExpenseEntityRef(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '-').toString(),
      name: (map['name'] ?? '-').toString(),
    );
  }
}

class ExpenseItemLine {
  final num amount;
  final String dueDate;
  final String itemDescription;
  final num qty;
  final num rate;

  const ExpenseItemLine({
    required this.amount,
    required this.dueDate,
    required this.itemDescription,
    required this.qty,
    required this.rate,
  });

  String get formattedAmount => formatRupiahExpense(amount);
  String get formattedRate => formatRupiahExpense(rate);

  factory ExpenseItemLine.fromJson(Map<String, dynamic> json) {
    return ExpenseItemLine(
      amount: (json['amount'] is num)
          ? json['amount'] as num
          : num.tryParse('${json['amount']}') ?? 0,
      dueDate: (json['dueDate'] ?? '-').toString(),
      itemDescription: (json['itemDescription'] ?? '-').toString(),
      qty: (json['qty'] is num)
          ? json['qty'] as num
          : num.tryParse('${json['qty']}') ?? 0,
      rate: (json['rate'] is num)
          ? json['rate'] as num
          : num.tryParse('${json['rate']}') ?? 0,
    );
  }
}

class ExpensePhase {
  final String actionAt;
  final String actionBy;
  final String actionByName;
  final String actionNote;
  final String phaseCode;
  final String phaseName;
  final int phaseOrder;
  final String phaseStatus;

  const ExpensePhase({
    required this.actionAt,
    required this.actionBy,
    required this.actionByName,
    required this.actionNote,
    required this.phaseCode,
    required this.phaseName,
    required this.phaseOrder,
    required this.phaseStatus,
  });

  bool get isApproved => phaseStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => phaseStatus.toUpperCase() == 'REJECTED';
  bool get isDone => actionAt.trim().isNotEmpty;

  factory ExpensePhase.fromJson(Map<String, dynamic> json) {
    return ExpensePhase(
      actionAt: (json['actionAt'] ?? '').toString(),
      actionBy: (json['actionBy'] ?? '').toString(),
      actionByName: (json['actionByName'] ?? '').toString(),
      actionNote: (json['actionNote'] ?? '').toString(),
      phaseCode: (json['phaseCode'] ?? '').toString(),
      phaseName: (json['phaseName'] ?? '-').toString(),
      phaseOrder: (json['phaseOrder'] is num)
          ? (json['phaseOrder'] as num).toInt()
          : int.tryParse('${json['phaseOrder']}') ?? 0,
      phaseStatus: (json['phaseStatus'] ?? 'PENDING').toString(),
    );
  }
}

class ExpenseRequestDetail {
  final String id;
  final num amount;
  final bool canResubmit;
  final ExpenseNamedRef client;
  final String createdAt;
  final String createdBy;
  final String createdByEmail;
  final String currentPhase;
  final List<ExpenseItemLine> items;
  final ExpenseEntityRef entity;
  final List<dynamic> evidenceFile;
  final String formType;
  final String invoiceDate;
  final String notes;
  final String operationExpense;
  final List<ExpensePhase> phaseOfRequest;
  final ExpenseNamedRef project;
  final String requestDate;
  final String requestNumber;
  final int revisionCount;
  final String status;
  final String updatedAt;
  final List<dynamic> uploadFile;

  const ExpenseRequestDetail({
    required this.id,
    required this.amount,
    required this.canResubmit,
    required this.client,
    required this.createdAt,
    required this.createdBy,
    required this.createdByEmail,
    required this.currentPhase,
    required this.items,
    required this.entity,
    required this.evidenceFile,
    required this.formType,
    required this.invoiceDate,
    required this.notes,
    required this.operationExpense,
    required this.phaseOfRequest,
    required this.project,
    required this.requestDate,
    required this.requestNumber,
    required this.revisionCount,
    required this.status,
    required this.updatedAt,
    required this.uploadFile,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  String get formattedAmount => formatRupiahExpense(amount);

  List<dynamic> get allFiles => [...evidenceFile, ...uploadFile];

  factory ExpenseRequestDetail.fromJson(Map<String, dynamic> json) {
    final detailInformation = (json['detailInformation'] is Map)
        ? Map<String, dynamic>.from(json['detailInformation'] as Map)
        : <String, dynamic>{};
    final rawItems = (detailInformation['items'] is List)
        ? detailInformation['items'] as List
        : const [];

    final rawPhases = (json['phaseOfRequest'] is List)
        ? json['phaseOfRequest'] as List
        : const [];

    final createdByUser = (json['createdByUser'] is Map)
        ? Map<String, dynamic>.from(json['createdByUser'] as Map)
        : <String, dynamic>{};

    return ExpenseRequestDetail(
      id: (json['id'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? json['amount'] as num
          : num.tryParse('${json['amount']}') ?? 0,
      canResubmit: json['canResubmit'] == true,
      client: ExpenseNamedRef.fromJson(json['client']),
      createdAt: (json['createdAt'] ?? '-').toString(),
      createdBy: (json['createdBy'] ?? '-').toString(),
      createdByEmail: (createdByUser['email'] ?? '-').toString(),
      currentPhase: (json['currentPhase'] ?? '-').toString(),
      items: rawItems
          .map(
            (e) =>
                ExpenseItemLine.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      entity: ExpenseEntityRef.fromJson(json['entity']),
      evidenceFile: (json['evidenceFile'] is List)
          ? json['evidenceFile'] as List
          : const [],
      formType: (json['formType'] ?? '-').toString(),
      invoiceDate: (json['invoiceDate'] ?? '').toString(),
      notes: (json['notes'] ?? '-').toString(),
      operationExpense: (json['operationExpense'] ?? '-').toString(),
      phaseOfRequest: rawPhases
          .map(
            (e) => ExpensePhase.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      project: ExpenseNamedRef.fromJson(json['project']),
      requestDate: (json['requestDate'] ?? '-').toString(),
      requestNumber: (json['requestNumber'] ?? '-').toString(),
      revisionCount: (json['revisionCount'] is num)
          ? (json['revisionCount'] as num).toInt()
          : int.tryParse('${json['revisionCount']}') ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
      updatedAt: (json['updatedAt'] ?? '-').toString(),
      uploadFile: (json['uploadFile'] is List)
          ? json['uploadFile'] as List
          : const [],
    );
  }
}
