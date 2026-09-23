import 'package:json_annotation/json_annotation.dart';

import 'package:__APP_NAME__/features/__FEATURE__/domain/entities/__ENTITY__.dart';

part '__ENTITY___model.g.dart';

@JsonSerializable()
class __ENTITY_CLASS__Model extends __ENTITY_CLASS__ {
  const __ENTITY_CLASS__Model({required super.id, required super.name});

  factory __ENTITY_CLASS__Model.fromJson(Map<String, dynamic> json) =>
      _$__ENTITY_CLASS__ModelFromJson(json);

  Map<String, dynamic> toJson() => _$__ENTITY_CLASS__ModelToJson(this);

  __ENTITY_CLASS__Model copyWith({String? id, String? name}) =>
      __ENTITY_CLASS__Model(id: id ?? this.id, name: name ?? this.name);
}
