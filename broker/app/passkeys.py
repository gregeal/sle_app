from __future__ import annotations

import hashlib
import json

from webauthn import (
    base64url_to_bytes,
    generate_authentication_options,
    generate_registration_options,
    options_to_json,
    verify_authentication_response,
    verify_registration_response,
)
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria,
    PublicKeyCredentialDescriptor,
    ResidentKeyRequirement,
    UserVerificationRequirement,
)

from .config import Settings
from .store import BrokerStore, PasskeyCredential


def registration_options(store: BrokerStore, settings: Settings, email: str) -> dict:
    existing = store.passkeys_for_email(email)
    options = generate_registration_options(
        rp_id=_rp_id(settings),
        rp_name="SLE Prep",
        # Avoid embedding the email address as the discoverable credential's
        # user handle. Authentication is still bound to the server challenge.
        user_id=hashlib.sha256(email.encode()).digest(),
        user_name=email,
        user_display_name=email,
        exclude_credentials=[
            PublicKeyCredentialDescriptor(id=credential.credential_id) for credential in existing
        ],
        authenticator_selection=AuthenticatorSelectionCriteria(
            resident_key=ResidentKeyRequirement.REQUIRED,
            user_verification=UserVerificationRequirement.REQUIRED,
        ),
    )
    challenge_id = store.put_challenge(
        kind="passkey-register",
        email=email,
        challenge=options.challenge,
    )
    return {"challengeId": challenge_id, "publicKey": json.loads(options_to_json(options))}


def finish_registration(
    store: BrokerStore,
    settings: Settings,
    email: str,
    challenge_id: str,
    credential: dict,
) -> None:
    row = store.consume_challenge(challenge_id, "passkey-register")
    if row is None or row["email"] != email:
        raise ValueError("registration challenge expired")
    verification = verify_registration_response(
        credential=credential,
        expected_challenge=bytes(row["challenge"]),
        expected_rp_id=_rp_id(settings),
        expected_origin=settings.public_origin,
        require_user_verification=True,
    )
    transports = credential.get("response", {}).get("transports") or []
    store.save_passkey(
        email,
        PasskeyCredential(
            credential_id=verification.credential_id,
            public_key=verification.credential_public_key,
            sign_count=verification.sign_count,
            transports=[str(value) for value in transports],
        ),
    )


def authentication_options(store: BrokerStore, settings: Settings, email: str) -> dict:
    credentials = store.passkeys_for_email(email)
    if not credentials:
        raise LookupError("no passkey")
    options = generate_authentication_options(
        rp_id=_rp_id(settings),
        allow_credentials=[
            PublicKeyCredentialDescriptor(id=credential.credential_id) for credential in credentials
        ],
        user_verification=UserVerificationRequirement.REQUIRED,
    )
    challenge_id = store.put_challenge(
        kind="passkey-login",
        email=email,
        challenge=options.challenge,
    )
    return {"challengeId": challenge_id, "publicKey": json.loads(options_to_json(options))}


def finish_authentication(
    store: BrokerStore,
    settings: Settings,
    challenge_id: str,
    credential: dict,
) -> str:
    row = store.consume_challenge(challenge_id, "passkey-login")
    if row is None:
        raise ValueError("authentication challenge expired")
    credential_id = base64url_to_bytes(credential.get("rawId") or credential.get("id") or "")
    stored = store.passkey_by_id(credential_id)
    if stored is None or stored[0] != row["email"]:
        raise ValueError("unknown credential")
    email, passkey = stored
    verification = verify_authentication_response(
        credential=credential,
        expected_challenge=bytes(row["challenge"]),
        expected_rp_id=_rp_id(settings),
        expected_origin=settings.public_origin,
        credential_public_key=passkey.public_key,
        credential_current_sign_count=passkey.sign_count,
        require_user_verification=True,
    )
    store.update_passkey_count(passkey.credential_id, verification.new_sign_count)
    return email


def _rp_id(settings: Settings) -> str:
    from .security import relying_party_id

    return relying_party_id(settings)
