import '../course/b_to_c_course.dart';

class DiagnosticPassage {
  const DiagnosticPassage(this.skill, this.band, this.text, this.questions);
  final String skill, band, text;
  final List<CourseQuestion> questions;
}

const placementPassages = [
  DiagnosticPassage(
    'reading',
    'foundation',
    'La réunion de l’équipe aura lieu mardi à neuf heures dans la salle 203. Apportez votre calendrier. Si vous travaillez à distance, demandez le lien à Nadia avant lundi midi.',
    [
      CourseQuestion(
        'Quand a lieu la réunion ?',
        ['Mardi à neuf heures', 'Lundi à midi', 'Mardi à midi'],
        0,
        'La première phrase donne la date et l’heure.',
      ),
      CourseQuestion(
        'Que doit faire une personne à distance ?',
        ['Réserver la salle', 'Demander le lien à Nadia', 'Annuler la réunion'],
        1,
        'Elle doit demander le lien avant lundi midi.',
      ),
    ],
  ),
  DiagnosticPassage(
    'reading',
    'complex',
    'La direction envisage de centraliser les demandes afin de réduire les doublons. Cette mesure ne garantirait toutefois pas un traitement plus rapide : sans clarification des responsabilités, les délais pourraient simplement se déplacer vers l’équipe centrale. Le projet pilote devrait donc mesurer aussi la qualité des transferts.',
    [
      CourseQuestion(
        'Quelle réserve l’auteur exprime-t-il ?',
        [
          'La centralisation est interdite',
          'Les délais pourraient être déplacés',
          'Les doublons sont souhaitables',
        ],
        1,
        'La centralisation ne suffit pas sans responsabilités claires.',
      ),
      CourseQuestion(
        'Que devrait mesurer le projet ?',
        [
          'Seulement le nombre de demandes',
          'Seulement les coûts',
          'La qualité des transferts aussi',
        ],
        2,
        'La conclusion ajoute la qualité des transferts aux mesures utiles.',
      ),
    ],
  ),
  DiagnosticPassage(
    'listening',
    'foundation',
    'Bonjour, ici Marc. La formation commence jeudi à dix heures. Le groupe se retrouve à l’accueil. Apportez votre ordinateur, mais les documents seront fournis sur place.',
    [
      CourseQuestion(
        'Où retrouve-t-on le groupe ?',
        ['À l’accueil', 'Au stationnement', 'Dans la salle informatique'],
        0,
        'Le point de rendez-vous est l’accueil.',
      ),
      CourseQuestion(
        'Que faut-il apporter ?',
        ['Les documents imprimés', 'Un ordinateur', 'Le repas du groupe'],
        1,
        'Les documents sont fournis; l’ordinateur est à apporter.',
      ),
    ],
  ),
  DiagnosticPassage(
    'listening',
    'complex',
    'Je ne m’oppose pas au nouvel outil. Ce qui me préoccupe, c’est le calendrier proposé : les équipes devront apprendre son fonctionnement pendant la période la plus chargée. Si nous reportions le lancement d’un mois, nous pourrions former des personnes-ressources et réduire les interruptions, même si cela retarderait les économies prévues.',
    [
      CourseQuestion(
        'La personne rejette-t-elle l’outil ?',
        [
          'Oui, définitivement',
          'Non, elle conteste surtout le calendrier',
          'Elle refuse toute formation',
        ],
        1,
        'Elle distingue son soutien à l’outil de ses réserves sur le calendrier.',
      ),
      CourseQuestion(
        'Quel compromis propose-t-elle ?',
        [
          'Retarder le lancement pour mieux préparer les équipes',
          'Supprimer les personnes-ressources',
          'Lancer sans formation',
        ],
        0,
        'Le report favorise la préparation mais retarde les économies.',
      ),
    ],
  ),
];
