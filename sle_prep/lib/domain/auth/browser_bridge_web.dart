import 'dart:js_interop';

@JS('slePasskeys.register')
external JSPromise<JSString> _register(JSString optionsJson);

@JS('slePasskeys.authenticate')
external JSPromise<JSString> _authenticate(JSString optionsJson);

@JS('slePasskeys.navigate')
external void _navigate(JSString url);

@JS('slePasskeys.getAuthHint')
external JSString? _getAuthHint();

@JS('slePasskeys.setAuthHint')
external void _setAuthHint(JSString? email);

@JS('slePasskeys.supported')
external JSBoolean get _supported;

Future<String> createPasskey(String optionsJson) async =>
    (await _register(optionsJson.toJS).toDart).toDart;

Future<String> getPasskey(String optionsJson) async =>
    (await _authenticate(optionsJson.toJS).toDart).toDart;

void navigateBrowser(String url) => _navigate(url.toJS);

String? readAuthHint() => _getAuthHint()?.toDart;

void writeAuthHint(String? email) => _setAuthHint(email?.toJS);

bool get browserSupportsPasskeys => _supported.toDart;
