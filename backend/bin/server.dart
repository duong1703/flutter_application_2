import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router(notFoundHandler: _notFoundHandler)
  ..get('/', _rootHandler)
  ..get('/api/v1/check', _checkHandler)
  ..get('/api/v1/echo/<message>', _echoHandler)
  ..post('/api/v1/submit', _submitHandler);

final _headers = {'Content-Type': 'Application/json'};

Response _rootHandler(Request req) {
  return Response.ok(
    json.encode({'message': 'Hello , world!'}),
    headers: _headers,
  );
}

Response _checkHandler(Request request) {
  return Response.ok(
    json.encode({'message': 'Chào mừng bạn tới trang web'}),
    headers: _headers,
  );
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _submitHandler(Request request) async {
  try {
    final payload = await request.readAsString();

    final data = json.decode(payload);

    final name = data['name'] as String?;

    if (name != null && name.isNotEmpty) {
      final response = {'message': 'Chào mừng bạn $name'};

      return Response.ok(json.encode(response), headers: _headers);
    } else {
      final response = {'mesage': 'Server không nhận được tên của bạn'};

      return Response.badRequest(
        body: json.encode(response),
        headers: _headers,
      );
    }
  } catch (e) {
    final response = {
      'message': 'Yêu cầu không hợp lệ. Mã lỗi ${e.toString()}'
    };

    return Response.badRequest(
      body: json.encode(response),
      headers: _headers,
    );
  }
}

Response _notFoundHandler(Request request) {
  return Response.notFound(
    json.encode({'Không tìm thấy trang trên máy chủ'}),
    headers: _headers,
  );
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final corsHeader = createMiddleware(
    requestHandler: (request) {
      if (request.method == "OPTIONS") {
        return Response.ok('', headers: {
          'Access-Controll-Allow-Origin': '*',
          'Access-Controll-Allow-Method': 'GET, POST, PUT, PATCH, DELETE, HEAD',
          'Access-Controll-Allow-Headers': 'Content-Type, Authorizeation',
        });
      }
      return null;
    },
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Controll-Allow-Origin': '*',
        'Access-Controll-Allow-Method': 'GET, POST, PUT, PATCH, DELETE, HEAD',
        'Access-Controll-Allow-Headers': 'Content-Type, Authorizeation',
      });
    },
  );

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(corsHeader)
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on http:// ${server.address.host}:${server.port}');
}
