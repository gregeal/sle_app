import 'dart:convert';
import '../../data/db/database.dart';

/// Original synthetic-audio practice, not official assessment material.
/// Negative catalog IDs never enter ReadingAttempts.
final listeningLessons = <ReadingSet>[
  _lesson(
    -1,
    'B · Un échéancier révisé',
    'Bonjour à toutes et à tous. La consultation prévue mardi est reportée à jeudi, '
        'car plusieurs partenaires n’ont pas encore reçu les documents. Cela ne change '
        'pas la date de remise du rapport final, fixée au vendredi suivant. D’ici mardi '
        'midi, veuillez vérifier les chiffres de votre section et signaler toute donnée '
        'manquante à Nadia. Elle regroupera vos questions avant de communiquer avec les '
        'partenaires. Évitez donc de leur envoyer des demandes séparées. Si votre '
        'section est déjà complète, profitez de ce délai pour relire les recommandations. '
        'Notre objectif reste de remettre un rapport exact.',
    [
      _q(
        'Qu’est-ce qui est reporté?',
        [
          'Le rapport final',
          'La consultation',
          'La vérification des chiffres',
          'Toutes les activités',
        ],
        1,
        'La consultation passe de mardi à jeudi; la remise finale ne change pas.',
      ),
      _q(
        'Pourquoi faut-il passer par Nadia?',
        [
          'Pour éviter des demandes dispersées',
          'Pour annuler les questions',
          'Pour obtenir un congé',
          'Pour changer le mandat',
        ],
        0,
        'Nadia regroupe les questions avant de contacter les partenaires.',
      ),
      _q(
        'Que doivent faire les personnes ayant terminé leur section?',
        [
          'Attendre sans intervenir',
          'Contacter tous les partenaires',
          'Relire les recommandations',
          'Envoyer le rapport final',
        ],
        2,
        'Le délai supplémentaire sert à relire les recommandations.',
      ),
    ],
  ),
  _lesson(
    -2,
    'B · Accueillir une collègue',
    'À compter de lundi, Amélie se joindra à notre équipe pour trois mois. Elle '
        'connaît bien le traitement des demandes, mais elle n’a pas encore utilisé '
        'notre nouveau système. Pendant la première semaine, elle travaillera avec '
        'Karim, qui lui montrera comment enregistrer et classer les dossiers. Ne lui '
        'attribuez pas de dossiers urgents avant vendredi. Ce n’est pas une question '
        'de compétence : nous voulons lui laisser le temps de s’habituer à nos outils. '
        'Ensuite, elle pourra travailler de façon autonome. Si vous avez des procédures '
        'qui ne figurent pas dans le guide, transmettez-les à Karim.',
    [
      _q(
        'Quel soutien Amélie recevra-t-elle?',
        [
          'Un examen officiel',
          'Un mandat permanent',
          'Une formation avec Karim',
          'Un changement de poste',
        ],
        2,
        'Karim lui montrera le système pendant la première semaine.',
      ),
      _q(
        'Pourquoi éviter les dossiers urgents au début?',
        [
          'Elle manque de compétence',
          'Elle doit découvrir les outils',
          'Elle sera absente',
          'Tous les dossiers sont confidentiels',
        ],
        1,
        'La personne distingue la maîtrise des outils de la compétence professionnelle.',
      ),
      _q(
        'À qui transmettre les procédures absentes du guide?',
        ['Aux clients', 'Au service de sécurité', 'À personne', 'À Karim'],
        3,
        'Karim doit recevoir ces procédures pour les expliquer à Amélie.',
      ),
    ],
  ),
  _lesson(
    -3,
    'C · Une décision sous conditions',
    'Je suis favorable à la simplification du formulaire, à condition qu’elle '
        'ne réduise pas la qualité des renseignements recueillis. Supprimer une '
        'question uniquement parce qu’elle est difficile à comprendre ne règle pas '
        'nécessairement le problème. Il serait préférable de la reformuler et de la '
        'tester auprès de personnes ayant des besoins différents. Certes, cette '
        'démarche retarderait légèrement le lancement. Toutefois, un formulaire lancé '
        'trop vite risquerait d’augmenter les appels au soutien. Je propose donc un '
        'projet pilote limité. Si les erreurs diminuent sans perte d’information, '
        'nous pourrons élargir son utilisation. Sinon, nous devrons revoir les '
        'questions concernées avant le déploiement.',
    [
      _q(
        'Quelle est la position de la personne?',
        [
          'Un refus de toute simplification',
          'Un soutien sans réserve',
          'Un soutien sous condition de qualité',
          'Un abandon du formulaire',
        ],
        2,
        '« À condition que » exprime un soutien assorti d’une exigence de qualité.',
      ),
      _q(
        'Quel compromis est proposé?',
        [
          'Accepter un léger délai pour tester',
          'Supprimer toutes les questions difficiles',
          'Éliminer le soutien',
          'Déployer immédiatement partout',
        ],
        0,
        'Le test retarde le lancement, mais peut réduire les erreurs et les appels.',
      ),
      _q(
        'Que faire si le pilote entraîne une perte d’information?',
        [
          'Ignorer les résultats',
          'Élargir automatiquement',
          'Accuser les utilisateurs',
          'Revoir les questions',
        ],
        3,
        'Le dernier énoncé prévoit une révision si les conditions ne sont pas remplies.',
      ),
    ],
  ),
  _lesson(
    -4,
    'C · Désaccord et priorités',
    'Je comprends que votre équipe souhaite publier les résultats dès cette '
        'semaine. Pour ma part, je crains qu’une publication avant la vérification '
        'des données donne une impression de précision que nous ne pouvons pas '
        'encore garantir. Cela dit, garder le silence pourrait aussi nuire à la '
        'confiance de nos partenaires. Ne pourrait-on pas diffuser une mise à jour '
        'qui décrit les tendances, tout en indiquant les limites de l’analyse? '
        'Nous éviterions ainsi de présenter des chiffres provisoires comme définitifs. '
        'Si cette solution était retenue, il faudrait convenir d’une date pour publier '
        'les résultats validés. Sans cet engagement, la mise à jour pourrait être '
        'perçue comme une façon de repousser la décision plutôt qu’un effort de transparence.',
    [
      _q(
        'Quel risque présente une publication immédiate?',
        [
          'Un manque de graphiques',
          'Une fausse impression de précision',
          'Une réunion trop longue',
          'Une hausse des dépenses',
        ],
        1,
        'Les données non vérifiées pourraient paraître plus certaines qu’elles ne le sont.',
      ),
      _q(
        'Pourquoi ne pas attendre en silence?',
        [
          'Les résultats sont définitifs',
          'Les partenaires demandent des chiffres faux',
          'Le silence peut affaiblir la confiance',
          'La vérification est inutile',
        ],
        2,
        'Le silence pourrait lui aussi nuire à la confiance des partenaires.',
      ),
      _q(
        'Quelle condition rend le compromis crédible?',
        [
          'Fixer une date pour les résultats validés',
          'Cacher les limites',
          'Publier tous les chiffres provisoires',
          'Reporter sans date',
        ],
        0,
        'Une date ferme évite que la mise à jour soit perçue comme une manœuvre dilatoire.',
      ),
    ],
  ),
];

ReadingSet _lesson(
  int id,
  String title,
  String text,
  List<Map<String, dynamic>> questions,
) => ReadingSet(
  id: id,
  title: title,
  kind: 'ecoute',
  bodyFr: text,
  questions: jsonEncode(questions),
  source: 'original-listening-v1',
);

Map<String, dynamic> _q(
  String prompt,
  List<String> options,
  int correct,
  String explanation,
) => {
  'prompt': prompt,
  'options': options,
  'correctIndex': correct,
  'explanationFr': explanation,
};
