// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaConfig _$MediaConfigFromJson(Map<String, dynamic> json) => MediaConfig(
      binding: json['binding'] as String,
      className: json['className'] as String,
      metaClassName: json['metaClassName'] as String,
      classDefinePath: json['classDefinePath'] as String,
      baseName: json['baseName'] as String,
      permitMetaClass: json['permitMetaClass'] as bool,
      needMeta: json['needMeta'] as bool,
      needOverwrite: json['needOverwrite'] as bool,
      cleanUndefineAsset: json['cleanUndefineAsset'] as bool,
      cleanNoCitedAssetDefine: json['cleanNoCitedAssetDefine'] as bool,
      needBinding: json['needBinding'] as bool,
    );

Map<String, dynamic> _$MediaConfigToJson(MediaConfig instance) =>
    <String, dynamic>{
      'binding': instance.binding,
      'className': instance.className,
      'metaClassName': instance.metaClassName,
      'classDefinePath': instance.classDefinePath,
      'baseName': instance.baseName,
      'permitMetaClass': instance.permitMetaClass,
      'needMeta': instance.needMeta,
      'needOverwrite': instance.needOverwrite,
      'cleanUndefineAsset': instance.cleanUndefineAsset,
      'cleanNoCitedAssetDefine': instance.cleanNoCitedAssetDefine,
      'needBinding': instance.needBinding,
    };