/// Kept in sync with the broker's allowlisted transcription configuration.
const liveTranscriptionModel = 'gpt-live-transcribe';

Map<String, dynamic> buildTranscriptionSessionConfig() => {
  'expires_after': {'anchor': 'created_at', 'seconds': 60},
  'session': {
    'type': 'transcription',
    'audio': {
      'input': {
        'noise_reduction': {'type': 'near_field'},
        'transcription': {
          'model': liveTranscriptionModel,
          'languages': ['fr'],
          'delay': 'high',
          'prompt':
              'Pratique du français canadien par une personne apprenante. '
              'Contexte professionnel de la fonction publique du Canada. '
              'Transcrire fidèlement les mots prononcés, les hésitations et les '
              'autocorrections, sans corriger la grammaire ni inventer de mots.',
        },
        'turn_detection': null,
      },
    },
  },
};
