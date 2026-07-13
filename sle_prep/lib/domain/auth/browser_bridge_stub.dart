Future<String> createPasskey(String optionsJson) =>
    Future.error(UnsupportedError('Passkeys require a web browser.'));

Future<String> getPasskey(String optionsJson) =>
    Future.error(UnsupportedError('Passkeys require a web browser.'));

void navigateBrowser(String url) =>
    throw UnsupportedError('Browser navigation is only available on web.');

String? readAuthHint() => null;

void writeAuthHint(String? email) {}

bool get browserSupportsPasskeys => false;
