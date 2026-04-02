import 'dart:convert';

import 'profile_document.dart';

class FinanceProfile {
  final String? residencyInQatar;
  final String? haveBankChecks;
  final String? canGetBankChecks;
  final ProfileDocument? idCardFront;
  final ProfileDocument? idCardBack;
  final List<ProfileDocument> bankStatements;
  final List<ProfileDocument> additionalAttachments;

  const FinanceProfile({
    this.residencyInQatar,
    this.haveBankChecks,
    this.canGetBankChecks,
    this.idCardFront,
    this.idCardBack,
    this.bankStatements = const [],
    this.additionalAttachments = const [],
  });

  bool get hasRequiredDocuments =>
      idCardFront != null && idCardBack != null && bankStatements.isNotEmpty;

  FinanceProfile copyWith({
    String? residencyInQatar,
    String? haveBankChecks,
    String? canGetBankChecks,
    ProfileDocument? idCardFront,
    bool clearIdCardFront = false,
    ProfileDocument? idCardBack,
    bool clearIdCardBack = false,
    List<ProfileDocument>? bankStatements,
    List<ProfileDocument>? additionalAttachments,
  }) {
    return FinanceProfile(
      residencyInQatar: residencyInQatar ?? this.residencyInQatar,
      haveBankChecks: haveBankChecks ?? this.haveBankChecks,
      canGetBankChecks: canGetBankChecks ?? this.canGetBankChecks,
      idCardFront: clearIdCardFront ? null : (idCardFront ?? this.idCardFront),
      idCardBack: clearIdCardBack ? null : (idCardBack ?? this.idCardBack),
      bankStatements: bankStatements ?? this.bankStatements,
      additionalAttachments:
          additionalAttachments ?? this.additionalAttachments,
    );
  }

  Map<String, dynamic> toAnswersJson() {
    return {
      'residency_in_qatar': residencyInQatar,
      'have_bank_checks': haveBankChecks,
      'can_get_bank_checks': canGetBankChecks,
    };
  }

  static FinanceProfile fromCustomerMeta(List<dynamic> metaData) {
    final metaMap = <String, dynamic>{};
    final selectedEntries = <String, Map<String, dynamic>>{};
    for (final item in metaData) {
      if (item is Map) {
        final entry = Map<String, dynamic>.from(item);
        final key = entry['key'];
        if (key != null) {
          final normalizedKey = key.toString();
          final existingEntry = selectedEntries[normalizedKey];
          if (existingEntry == null) {
            selectedEntries[normalizedKey] = entry;
            metaMap[normalizedKey] = entry['value'];
            continue;
          }

          final existingId = _parseMetaId(existingEntry['id']) ?? -1;
          final currentId = _parseMetaId(entry['id']) ?? -1;

          if (currentId >= existingId) {
            selectedEntries[normalizedKey] = entry;
            metaMap[normalizedKey] = entry['value'];
          }
        }
      }
    }

    return FinanceProfile(
      residencyInQatar:
          _normalizeAnswer(_metaValue(metaMap, const [
        'finance_residency_in_qatar',
        'residency_in_qatar',
      ])),
      haveBankChecks:
          _normalizeAnswer(_metaValue(metaMap, const [
        'finance_have_bank_checks',
        'have_bank_checks',
      ])),
      canGetBankChecks:
          _normalizeAnswer(_metaValue(metaMap, const [
        'finance_can_get_bank_checks',
        'can_get_bank_checks',
      ])),
      idCardFront: _parseSingleDocument(_metaValue(metaMap, const [
        'finance_id_card_front',
        'id_card_front',
      ])),
      idCardBack: _parseSingleDocument(_metaValue(metaMap, const [
        'finance_id_card_back',
        'id_card_back',
      ])),
      bankStatements:
          _parseDocumentList(_metaValue(metaMap, const [
        'finance_bank_statements',
        'bank_statements',
      ])),
      additionalAttachments:
          _parseDocumentList(_metaValue(metaMap, const [
        'finance_additional_attachments',
        'additional_attachments',
      ])),
    );
  }

  static String? _normalizeAnswer(dynamic value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.toLowerCase() == 'yes') return 'Yes';
    if (normalized.toLowerCase() == 'no') return 'No';
    return normalized;
  }

  static ProfileDocument? _parseSingleDocument(dynamic raw) {
    final parsed = _parseRawJson(raw);
    if (parsed is Map<String, dynamic>) {
      return ProfileDocument.fromJson(parsed);
    }
    return null;
  }

  static List<ProfileDocument> _parseDocumentList(dynamic raw) {
    final parsed = _parseRawJson(raw);
    if (parsed is List) {
      return parsed
          .whereType<Map>()
          .map((item) => ProfileDocument.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    return const [];
  }

  static dynamic _parseRawJson(dynamic raw) {
    if (raw is Map<String, dynamic> || raw is List) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _parseMetaId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static dynamic _metaValue(
    Map<String, dynamic> metaMap,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!metaMap.containsKey(key)) continue;
      final value = metaMap[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }
}
