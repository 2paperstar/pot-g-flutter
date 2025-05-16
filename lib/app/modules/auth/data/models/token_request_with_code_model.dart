import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_request_with_code_model.freezed.dart';
part 'token_request_with_code_model.g.dart';

@freezed
sealed class TokenRequestWithCodeModel with _$TokenRequestWithCodeModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TokenRequestWithCodeModel({
    @Default('authorization_code') String grantType,
    required String code,
    required String codeVerifier,
    required String clientId,
    required String nonce,
  }) = _TokenRequestWithCodeModel;

  factory TokenRequestWithCodeModel.fromJson(Map<String, dynamic> json) =>
      _$TokenRequestWithCodeModelFromJson(json);
}
