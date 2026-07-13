(function () {
  const toBuffer = (value) => {
    const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
    const bytes = atob(padded);
    return Uint8Array.from(bytes, (char) => char.charCodeAt(0));
  };

  const toBase64Url = (value) => {
    const bytes = new Uint8Array(value);
    let binary = "";
    bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };

  const creationOptions = (source) => {
    const options = JSON.parse(source);
    options.challenge = toBuffer(options.challenge);
    options.user.id = toBuffer(options.user.id);
    options.excludeCredentials = (options.excludeCredentials || []).map((item) => ({
      ...item,
      id: toBuffer(item.id),
    }));
    return options;
  };

  const requestOptions = (source) => {
    const options = JSON.parse(source);
    options.challenge = toBuffer(options.challenge);
    options.allowCredentials = (options.allowCredentials || []).map((item) => ({
      ...item,
      id: toBuffer(item.id),
    }));
    return options;
  };

  const credentialJson = (credential) => {
    const response = credential.response;
    const result = {
      id: credential.id,
      rawId: toBase64Url(credential.rawId),
      type: credential.type,
      authenticatorAttachment: credential.authenticatorAttachment,
      clientExtensionResults: credential.getClientExtensionResults(),
      response: {
        clientDataJSON: toBase64Url(response.clientDataJSON),
      },
    };
    if (response.attestationObject) {
      result.response.attestationObject = toBase64Url(response.attestationObject);
      result.response.transports = response.getTransports ? response.getTransports() : [];
    } else {
      result.response.authenticatorData = toBase64Url(response.authenticatorData);
      result.response.signature = toBase64Url(response.signature);
      result.response.userHandle = response.userHandle
        ? toBase64Url(response.userHandle)
        : null;
    }
    return JSON.stringify(result);
  };

  window.slePasskeys = {
    supported: Boolean(window.PublicKeyCredential && navigator.credentials),
    register: async (source) => credentialJson(await navigator.credentials.create({
      publicKey: creationOptions(source),
    })),
    authenticate: async (source) => credentialJson(await navigator.credentials.get({
      publicKey: requestOptions(source),
    })),
    navigate: (url) => window.location.assign(url),
    getAuthHint: () => window.localStorage.getItem("sle_prep_auth_hint"),
    setAuthHint: (email) => {
      if (email) {
        window.localStorage.setItem("sle_prep_auth_hint", email);
      } else {
        window.localStorage.removeItem("sle_prep_auth_hint");
      }
    },
  };
}());
