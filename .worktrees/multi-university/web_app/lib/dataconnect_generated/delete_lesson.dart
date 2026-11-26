part of 'generated.dart';

class DeleteLessonVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteLessonVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteLessonData> dataDeserializer = (dynamic json)  => DeleteLessonData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteLessonData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteLessonData, void> ref() {
    
    return _dataConnect.mutation("DeleteLesson", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteLessonLessonDelete {
  final String id;
  DeleteLessonLessonDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLessonLessonDelete otherTyped = other as DeleteLessonLessonDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteLessonLessonDelete({
    required this.id,
  });
}

@immutable
class DeleteLessonData {
  final DeleteLessonLessonDelete? lesson_delete;
  DeleteLessonData.fromJson(dynamic json):
  
  lesson_delete = json['lesson_delete'] == null ? null : DeleteLessonLessonDelete.fromJson(json['lesson_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteLessonData otherTyped = other as DeleteLessonData;
    return lesson_delete == otherTyped.lesson_delete;
    
  }
  @override
  int get hashCode => lesson_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (lesson_delete != null) {
      json['lesson_delete'] = lesson_delete!.toJson();
    }
    return json;
  }

  DeleteLessonData({
    this.lesson_delete,
  });
}

