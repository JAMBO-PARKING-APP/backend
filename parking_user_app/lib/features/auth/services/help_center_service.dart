import 'package:parking_user_app/core/api_client.dart';

class HelpCenterService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getHelpItems({
    String? category,
    String? search,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        'help/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch help center'};
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  Future<Map<String, dynamic>> getHelpItemDetail(int itemId) async {
    try {
      final response = await _apiClient.get('help/$itemId/');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch help item'};
    }
    return {'success': false, 'message': 'Unknown error'};
  }
}
