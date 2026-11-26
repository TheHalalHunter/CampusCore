part of 'generated.dart';

class ListEnrollmentsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListEnrollmentsVariablesBuilder(this._dataConnect, );
  Deserializer<ListEnrollmentsData> dataDeserializer = (dynamic json)  => ListEnrollmentsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListEnrollmentsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListEnrollmentsData, void> ref() {
    
    return _dataConnect.query("ListEnrollments", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListEnrollmentsEnrollments {
  final double progressPercentage;
  ListEnrollmentsEnrollments.fromJson(dynamic json):
  
  progressPercentage = nativeFromJson<double>(json['progressPercentage']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnrollmentsEnrollments otherTyped = other as ListEnrollmentsEnrollments;
    return progressPercentage == otherTyped.progressPercentage;
    
  }
  @override
  int get hashCode => progressPercentage.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['progressPercentage'] = nativeToJson<double>(progressPercentage);
    return json;
  }

  ListEnrollmentsEnrollments({
    required this.progressPercentage,
  });
}

@immutable
class ListEnrollmentsData {
  final List<ListEnrollmentsEnrollments> enrollments;
  ListEnrollmentsData.fromJson(dynamic json):
  
  enrollments = (json['enrollments'] as List<dynamic>)
        .map((e) => ListEnrollmentsEnrollments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnrollmentsData otherTyped = other as ListEnrollmentsData;
    return enrollments == otherTyped.enrollments;
    
  }
  @override
  int get hashCode => enrollments.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['enrollments'] = enrollments.map((e) => e.toJson()).toList();
    return json;
  }

  ListEnrollmentsData({
    required this.enrollments,
  });
}

