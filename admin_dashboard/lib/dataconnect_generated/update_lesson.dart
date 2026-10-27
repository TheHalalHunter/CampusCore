part of 'generated.dart';

class UpdateLessonVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateLessonVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateLessonData> dataDeserializer = (dynamic json)  => UpdateLessonData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateLessonData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateLessonData, void> ref() {
    
    return _dataConnect.mutation("UpdateLesson", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateLessonLessonUpdate {
  final String id;
  UpdateLessonLessonUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLessonLessonUpdate otherTyped = other as UpdateLessonLessonUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateLessonLessonUpdate({
    required this.id,
  });
}

@immutable
class UpdateLessonData {
  final UpdateLessonLessonUpdate? lesson_update;
  UpdateLessonData.fromJson(dynamic json):
  
  lesson_update = json['lesson_update'] == null ? null : UpdateLessonLessonUpdate.fromJson(json['lesson_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateLessonData otherTyped = other as UpdateLessonData;
    return lesson_update == otherTyped.lesson_update;
    
  }
  @override
  int get hashCode => lesson_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (lesson_update != null) {
      json['lesson_update'] = lesson_update!.toJson();
    }
    return json;
  }

  UpdateLessonData({
    this.lesson_update,
  });
}

