part of 'generated.dart';

class CreateLessonVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateLessonVariablesBuilder(this._dataConnect, );
  Deserializer<CreateLessonData> dataDeserializer = (dynamic json)  => CreateLessonData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateLessonData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateLessonData, void> ref() {
    
    return _dataConnect.mutation("CreateLesson", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateLessonLessonInsert {
  final String id;
  CreateLessonLessonInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLessonLessonInsert otherTyped = other as CreateLessonLessonInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateLessonLessonInsert({
    required this.id,
  });
}

@immutable
class CreateLessonData {
  final CreateLessonLessonInsert lesson_insert;
  CreateLessonData.fromJson(dynamic json):
  
  lesson_insert = CreateLessonLessonInsert.fromJson(json['lesson_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLessonData otherTyped = other as CreateLessonData;
    return lesson_insert == otherTyped.lesson_insert;
    
  }
  @override
  int get hashCode => lesson_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['lesson_insert'] = lesson_insert.toJson();
    return json;
  }

  CreateLessonData({
    required this.lesson_insert,
  });
}

