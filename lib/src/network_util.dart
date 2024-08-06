import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_polyline_points/src/utils/polyline_decoder.dart';
import 'package:flutter_polyline_points/src/utils/polyline_request.dart';
import 'package:http/http.dart' as http;

import 'utils/polyline_result.dart';

class NetworkUtil {
  static const String STATUS_OK = "ok";

  ///Get the encoded string from google directions api
  ///
  Future<List<PolylineResult>> getRouteBetweenCoordinates({
    required PolylineRequest request,
    String? googleApiKey,
  }) async {
    List<PolylineResult> results = [];

    var response = await http.get(
      request.toUri(apiKey: googleApiKey),
      headers: request.headers,
    );
    // debugPrint('${response.body}');
    if (response.statusCode == 200) {
      var parsedJson = json.decode(response.body);
      if (parsedJson["status"]?.toLowerCase() == STATUS_OK &&
          parsedJson["routes"] != null &&
          parsedJson["routes"].isNotEmpty) {
        List<dynamic> routeList = parsedJson["routes"];
        for (var route in routeList) {

          List<Map<String, dynamic>> extractedData = [];

          for (var leg in route['legs']) {
            for (var step in leg['steps']) {
              Map<String, dynamic> stepData = {
                'html_instructions': step['html_instructions'],
                'start_location': step['start_location'],
                'end_location': step['end_location']
              };
              extractedData.add(stepData);
            }
          }

          print(extractedData);

          results.add(PolylineResult(
            points: PolylineDecoder.run(route["overview_polyline"]["points"]),
            errorMessage: "",
            status: parsedJson["status"],
            totalDistanceValue: route['legs']
                .map((leg) => leg['distance']['value'])
                .reduce((v1, v2) => v1 + v2),
            distanceTexts: <String>[
              ...route['legs'].map((leg) => leg['distance']['text'])
            ],
            distanceValues: <int>[
              ...route['legs'].map((leg) => leg['distance']['value'])
            ],
            overviewPolyline: route["overview_polyline"]["points"],
            totalDurationValue: route['legs']
                .map((leg) => leg['duration']['value'])
                .reduce((v1, v2) => v1 + v2),
            durationTexts: <String>[
              ...route['legs'].map((leg) => leg['duration']['text'])
            ],
            durationValues: <int>[
              ...route['legs'].map((leg) => leg['duration']['value'])
            ],
            endAddress: route["legs"].last['end_address'],
            startAddress: route["legs"].first['start_address'],
            directions: extractedData,
          ));
        }
      } else {
        throw Exception(
            "Unable to get route: Response ---> ${parsedJson["status"]} ");
      }
    }
    return results;
  }
}
