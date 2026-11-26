part of 'generated.dart';

class GetEnrollmentVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetEnrollmentVariablesBuilder(this._dataConnect, );
  Deserializer<GetEnrollmentData> dataDeserializer = (dynamic json)  => GetEnrollmentData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetEnrollmentData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetEnrollmentData, void> ref() {
    
    return _dataConnect.query("GetEnrollment", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetEnrollmentEnrollment {
  final double progressPercentage;
  GetEnrollmentEnrollment.fromJson(dynamic json):
  
  progressPercentage = nativeFromJson<double>(json['progressPercentage']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnrollmentEnrollment otherTyped = other as GetEnrollmentEnrollment;
    return progressPercentage == otherTyped.progressPercentage;
    
  }
  @override
  int get hashCode => progressPercentage.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['progressPercentage'] = nativeToJson<double>(progressPercentage);
    return json;
  }

  GetEnrollmentEnrollment({
    required this.progressPercentage,
  });
}

@immutable
class GetEnrollmentData {
  final GetEnrollmentEnrollment? enrollment;
  GetEnrollmentData.fromJson(dynamic json):
  
  enrollment = json['enrollment'] == null ? null : GetEnrollmentEnrollment.fromJson(json['enrollment']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnrollmentData otherTyped = other as GetEnrollmentData;
    return enrollment == otherTyped.enrollment;
    
  }
  @override
  int get hashCode => enrollment.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (enrollment != null) {
      json['enrollment'] = enrollment!.toJson();
    }
    return json;
  }

  GetEnrollmentData({
    this.enrollment,
  });
}

