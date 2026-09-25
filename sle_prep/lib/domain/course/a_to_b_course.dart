import 'b_to_c_course.dart';

// Original SLE A → B teaching material, not CEFR level equivalence or test items.
const aToBModules = [
  CourseModule(
    1,
    'Se présenter et parler du quotidien',
    'Construire des phrases simples et donner des renseignements familiers.',
  ),
  CourseModule(
    2,
    'Demander et préciser',
    'Poser des questions et comprendre dates, heures et quantités.',
  ),
  CourseModule(
    3,
    'Situer et décrire',
    'Décrire un lieu, des personnes et du matériel avec précision.',
  ),
  CourseModule(
    4,
    'Agir avec les autres',
    'Faire une demande et expliquer une procédure courte.',
  ),
  CourseModule(
    5,
    'Raconter ce qui s’est passé',
    'Distinguer une action terminée du contexte passé.',
  ),
  CourseModule(
    6,
    'Prévoir et expliquer',
    'Parler de projets concrets et justifier un choix simple.',
  ),
  CourseModule(
    7,
    'Comprendre et transmettre un message',
    'Lire un courriel factuel, écrire une réponse et vérifier ce qui a été entendu.',
  ),
  CourseModule(
    8,
    'Gérer une situation moins familière',
    'Expliquer un incident et mener un échange factuel suivi.',
  ),
];

const aToBLessons = <CourseLesson>[
  CourseLesson(
    id: 'ab-01-identity',
    module: 1,
    foundation: true,
    title: 'Me présenter au travail',
    objective:
        'Dire qui je suis, où je travaille et ce que je fais avec des phrases courtes.',
    teaching: [
      'Une phrase de base contient souvent un sujet et un verbe : « je travaille ». Ajoutez ensuite une information utile : « je travaille à Ottawa ». Commencez par une idée à la fois.',
      'Être sert notamment à présenter une fonction : je suis, tu es, il ou elle est, nous sommes, vous êtes, ils ou elles sont. Devant un métier sans précision, dites « je suis analyste », sans un ou une.',
      'Apprenez les noms avec leur article : un service, une équipe, le bureau, la réunion. Devant une voyelle, le et la deviennent l’ : l’équipe. Au pluriel, utilisez les ou des selon le sens.',
      'Avec une personne que vous ne connaissez pas, vous est un choix professionnel courant. Demandez « Comment vous appelez-vous ? » ou « Vous vous appelez comment ? »; les deux permettent un échange clair.',
    ],
    simpleExample: 'Je suis Sam. Je travaille ici.',
    developedExample:
        'Bonjour, je m’appelle Sam. Je suis analyste dans le service des opérations. Je travaille à Gatineau. Je prépare des rapports pour mon équipe.',
    phrases: [
      'Je m’appelle… — My name is…',
      'Je suis responsable de… — I am responsible for…',
      'Et vous ? — And you?',
    ],
    exercise:
        'Présentez une personne fictive avec son nom, sa fonction et son lieu de travail.',
    modelAnswer:
        'Elle s’appelle Léa. Elle est adjointe administrative. Elle travaille à Québec.',
    questions: [
      CourseQuestion(
        'Nous ___ dans la même équipe.',
        ['sommes', 'êtes', 'sont'],
        0,
        'Avec nous, être se conjugue sommes.',
      ),
      CourseQuestion(
        'Quelle phrase présente une fonction simplement ?',
        ['Je suis une analyste de.', 'Je suis analyste.', 'Je analyste suis.'],
        1,
        'Sans précision particulière, le métier suit être sans article.',
      ),
    ],
    speakingTask:
        'Présentez-vous avec quatre phrases courtes. Demandez ensuite à votre partenaire son nom et sa fonction. Utilisez une identité fictive si vous préférez.',
    criteria: [
      'J’ai indiqué une fonction et un lieu.',
      'Mes phrases contiennent un verbe.',
      'J’ai posé une question simple à mon interlocuteur.',
    ],
  ),
  CourseLesson(
    id: 'ab-02-routine',
    module: 1,
    foundation: true,
    title: 'Décrire ma journée habituelle',
    objective:
        'Parler de tâches régulières au présent et dire ce que je ne fais pas.',
    teaching: [
      'Pour beaucoup de verbes en -er, retirez -er puis ajoutez -e, -es, -e, -ons, -ez, -ent : je prépare, nous préparons, vous préparez. Aller est une exception, pas un verbe régulier de ce groupe.',
      'Avoir sert notamment à exprimer une possession ou une obligation avec un nom : j’ai un dossier, nous avons une réunion. Ses formes fréquentes sont ai, as, a, avons, avez, ont.',
      'Placez souvent devant le verbe principal pour une habitude : « je vérifie souvent les demandes ». Tous les matins, parfois et le vendredi situent aussi les tâches.',
      'À l’écrit, la négation encadre le verbe : « je ne travaille pas le samedi ». Devant une voyelle, ne devient n’. À l’oral, ne est souvent omis; apprenez néanmoins la forme complète pour écrire.',
    ],
    simpleExample: 'Je travaille. Je fais des choses.',
    developedExample:
        'Tous les matins, je consulte les messages et je prépare les dossiers urgents. Nous avons une réunion le mardi. Je ne réponds pas aux demandes techniques; je les transmets à un collègue.',
    phrases: [
      'Tous les matins… — Every morning…',
      'Je m’occupe de… — I look after…',
      'Je ne… pas — I do not…',
    ],
    exercise:
        'Écrivez une tâche habituelle, puis une tâche que votre équipe ne fait pas.',
    modelAnswer:
        'Nous préparons les réunions. Nous ne réparons pas les ordinateurs.',
    questions: [
      CourseQuestion(
        'Vous ___ les demandes chaque matin.',
        ['traitons', 'traitez', 'traitent'],
        1,
        'Vous prend la terminaison -ez avec traiter au présent.',
      ),
      CourseQuestion(
        'Choisissez la négation écrite complète.',
        [
          'Je pas travaille ici.',
          'Je travaille ne pas ici.',
          'Je ne travaille pas ici.',
        ],
        2,
        'Ne et pas entourent travaille.',
      ),
    ],
    speakingTask:
        'Décrivez trois tâches d’une journée habituelle. Précisez leur fréquence et une tâche qui ne relève pas de vous. Répondez à une question sur votre horaire.',
    criteria: [
      'J’ai utilisé le présent pour mes habitudes.',
      'J’ai donné un repère de fréquence.',
      'J’ai expliqué une limite avec une négation claire.',
    ],
  ),
  CourseLesson(
    id: 'ab-03-questions',
    module: 2,
    foundation: true,
    title: 'Obtenir le renseignement manquant',
    objective:
        'Choisir un mot interrogatif et demander une précision sans deviner.',
    teaching: [
      'Qui demande une personne; où, un lieu; quand, un moment; comment, une manière; pourquoi, une raison. Quel ou quelle accompagne un nom : quel document, quelle salle.',
      'Est-ce que permet une question avec l’ordre habituel du sujet et du verbe : « Est-ce que vous avez le formulaire ? ». Avec un mot interrogatif : « Où est-ce que vous travaillez ? ».',
      'Une intonation montante peut suffire dans une conversation : « Vous avez le formulaire ? ». L’inversion est une autre possibilité, mais elle n’est pas obligatoire pour communiquer correctement.',
      'Si une information manque, posez une question ciblée. « Quel dossier ? » est plus utile que répéter toute la demande. Puis reformulez la réponse pour confirmer votre compréhension.',
    ],
    simpleExample: 'Le document ? Je ne sais pas.',
    developedExample:
        'Quel document dois-je envoyer ? Et à qui est-ce que je dois le transmettre ? D’accord : le formulaire signé, à Mme Roy, avant vendredi.',
    phrases: [
      'De quel document s’agit-il ?',
      'À qui dois-je l’envoyer ?',
      'Si je comprends bien…',
    ],
    exercise:
        'Demandez le lieu et l’heure d’une réunion sans utiliser seulement « la réunion ? ».',
    modelAnswer: 'Où se tient la réunion ? À quelle heure commence-t-elle ?',
    questions: [
      CourseQuestion(
        'Pour connaître une raison, je demande…',
        ['où', 'pourquoi', 'qui'],
        1,
        'Pourquoi porte sur la raison.',
      ),
      CourseQuestion(
        '___ salle avez-vous réservée ?',
        ['Quel', 'Quels', 'Quelle'],
        2,
        'Salle est féminin singulier : quelle.',
      ),
    ],
    speakingTask:
        'Un collègue vous demande d’envoyer un document sans autre précision. Posez trois questions utiles, puis confirmez les renseignements reçus.',
    criteria: [
      'Mes questions portent sur des renseignements différents.',
      'J’ai choisi les mots interrogatifs adaptés.',
      'J’ai confirmé ce que je dois faire.',
    ],
  ),
  CourseLesson(
    id: 'ab-04-time',
    module: 2,
    foundation: true,
    title: 'Comprendre heures, dates et quantités',
    objective:
        'Fixer un rendez-vous et vérifier une information numérique importante.',
    teaching: [
      'Pour un rendez-vous précis, dites « mardi à neuf heures ». Pour une habitude, « le mardi » signifie généralement chaque mardi. La préposition à introduit l’heure.',
      'Dans les horaires professionnels, le système de vingt-quatre heures évite les ambiguïtés : quinze heures correspond à trois heures de l’après-midi. Distinguez quinze et cinquante à l’écoute en demandant confirmation.',
      'Une date peut se dire « le douze mai »; le premier jour du mois se dit « le premier mai ». Ne confondez pas la date limite avec la date de la rencontre.',
      'Quand un chiffre est important, vérifiez-le : « Vous avez dit seize dossiers ? ». Pour un numéro de téléphone ou une référence, vous pouvez demander une répétition chiffre par chiffre.',
    ],
    simpleExample: 'La réunion est mardi. Il faut des copies.',
    developedExample:
        'La réunion aura lieu mardi à quinze heures, dans la salle 204. Nous attendons seize personnes. Pouvez-vous préparer vingt copies avant midi ?',
    phrases: [
      'À quelle heure exactement ?',
      'Vous avez dit seize ou six ?',
      'La date limite est le…',
    ],
    exercise:
        'Confirmez une rencontre à 14 h 30 et une date limite fixée au 8 juin.',
    modelAnswer:
        'La rencontre commence à quatorze heures trente. Je dois envoyer le document au plus tard le huit juin.',
    questions: [
      CourseQuestion(
        '15 h correspond à…',
        [
          'cinq heures du matin',
          'trois heures de l’après-midi',
          'cinq heures de l’après-midi',
        ],
        1,
        '15 h correspond à 3 h après midi.',
      ),
      CourseQuestion(
        '« Le mardi, je travaille ici » décrit généralement…',
        ['une habitude', 'une date limite', 'une quantité'],
        0,
        'Le jour avec un article désigne ici une répétition habituelle.',
      ),
    ],
    speakingTask:
        'Proposez une date et une heure pour une rencontre. Indiquez un nombre de participants et une date limite. Demandez à votre partenaire de confirmer les chiffres.',
    criteria: [
      'J’ai distingué l’heure et la date limite.',
      'J’ai exprimé une quantité clairement.',
      'J’ai vérifié un renseignement numérique.',
    ],
  ),
  CourseLesson(
    id: 'ab-05-places',
    module: 3,
    foundation: true,
    title: 'Situer un lieu et guider quelqu’un',
    objective: 'Indiquer où se trouve un service et expliquer un trajet court.',
    teaching: [
      'À situe souvent une ville : à Montréal. Dans décrit l’intérieur : dans le bureau. Chez situe une personne ou son lieu d’activité : chez le médecin. Le choix dépend du nom qui suit.',
      'À + le devient au; à + les devient aux : au bureau, aux archives. De + le devient du; de + les devient des : près du bureau. À la et de la ne se contractent pas.',
      'Devant, derrière, à gauche de et à côté de décrivent une position. Dites d’abord le point de départ, puis deux ou trois étapes utiles, sans accumuler trop de détails.',
      'Vérifiez le résultat : « Vous voyez l’accueil ? ». Si la personne est perdue, reprenez à partir d’un repère commun plutôt que répéter plus vite.',
    ],
    simpleExample: 'Le bureau est là. Allez là-bas.',
    developedExample:
        'Le bureau des ressources humaines se trouve au deuxième étage, à côté de l’ascenseur. Depuis l’accueil, prenez le couloir à gauche. La porte est au fond, en face de la salle de réunion.',
    phrases: [
      'À côté de… — Next to…',
      'En face de… — Opposite…',
      'À partir de l’accueil… — From reception…',
    ],
    exercise:
        'Situez une imprimante près du bureau et une salle à droite de l’accueil.',
    modelAnswer:
        'L’imprimante est près du bureau. La salle est à droite de l’accueil.',
    questions: [
      CourseQuestion(
        'Je vais ___ bureau.',
        ['à le', 'au', 'aux'],
        1,
        'À + le se contracte en au.',
      ),
      CourseQuestion(
        'La salle est « en face de » l’accueil : elle est…',
        [
          'à l’intérieur de l’accueil',
          'loin dans une autre ville',
          'du côté opposé',
        ],
        2,
        'En face de situe du côté opposé à un repère.',
      ),
    ],
    speakingTask:
        'Guidez un nouveau collègue de l’entrée à une salle. Donnez trois repères maximum, puis vérifiez qu’il a compris.',
    criteria: [
      'J’ai indiqué le point de départ.',
      'J’ai utilisé des repères précis.',
      'J’ai vérifié la compréhension du trajet.',
    ],
  ),
  CourseLesson(
    id: 'ab-06-description',
    module: 3,
    foundation: true,
    title: 'Décrire du matériel et des besoins',
    objective:
        'Accorder des adjectifs fréquents et expliquer un besoin concret.',
    teaching: [
      'Un adjectif s’accorde généralement avec le nom : un dossier urgent, une demande urgente, des demandes urgentes. Le féminin se forme souvent avec -e et le pluriel avec -s, mais il existe des exceptions.',
      'Beaucoup d’adjectifs suivent le nom : une salle disponible, un formulaire incomplet. Certains adjectifs courants le précèdent : un petit bureau, une nouvelle collègue.',
      'Pour identifier un objet, indiquez son nom puis une caractéristique utile : taille, état, fonction. « L’imprimante du deuxième étage » est plus précis que « la chose là-bas ».',
      'J’ai besoin de introduit un besoin. Je cherche introduit directement l’objet recherché : « je cherche une salle ». Évitez de traduire mot à mot une construction anglaise.',
    ],
    simpleExample: 'J’ai besoin d’une salle. Elle doit être bonne.',
    developedExample:
        'Je cherche une petite salle disponible demain matin. Nous avons besoin d’un écran et de quatre chaises. La salle habituelle est occupée toute la journée.',
    phrases: [
      'J’ai besoin de… — I need…',
      'Je cherche… — I am looking for…',
      'Il manque… — … is missing',
    ],
    exercise: 'Décrivez deux demandes urgentes et une salle disponible.',
    modelAnswer:
        'J’ai reçu deux demandes urgentes. Pour les traiter ensemble, nous cherchons une salle disponible.',
    questions: [
      CourseQuestion(
        'Deux demandes ___ arrivent ce matin.',
        ['urgent', 'urgents', 'urgentes'],
        2,
        'Demandes est féminin pluriel : urgentes.',
      ),
      CourseQuestion(
        'Quelle formulation est correcte ?',
        [
          'Je cherche une salle.',
          'Je cherche pour une salle.',
          'Je besoin une salle.',
        ],
        0,
        'Chercher prend directement son complément dans ce sens.',
      ),
    ],
    speakingTask:
        'Décrivez le matériel nécessaire pour une petite réunion. Précisez ce qui est disponible et ce qui manque, puis répondez à une question sur la salle.',
    criteria: [
      'J’ai nommé les objets utiles.',
      'J’ai utilisé des descriptions précises.',
      'J’ai distingué le matériel disponible du matériel manquant.',
    ],
  ),
  CourseLesson(
    id: 'ab-07-requests',
    module: 4,
    foundation: true,
    title: 'Faire une demande polie',
    objective:
        'Utiliser pouvoir, vouloir et devoir pour demander une action concrète.',
    teaching: [
      'Pouvoir exprime une possibilité : je peux, vous pouvez. Devoir exprime notamment une obligation : je dois, nous devons. Après ces verbes, le deuxième verbe reste à l’infinitif : vous pouvez envoyer.',
      'Pour demander poliment, utilisez « pouvez-vous… ? » ou « est-ce que vous pouvez… ? ». Pourriez-vous et je voudrais sont aussi des formules utiles à apprendre comme ensembles, sans maîtriser tout le conditionnel.',
      'Une demande claire précise l’action, l’objet et le délai. Ajoutez une courte raison si elle aide : « pour préparer la rencontre ». La politesse ne remplace pas l’information.',
      'Pour refuser, indiquez ce qui est impossible puis une solution concrète : « je ne peux pas aujourd’hui, mais je peux demain ». Évitez une promesse que vous ne pouvez pas tenir.',
    ],
    simpleExample: 'Envoyez le document.',
    developedExample:
        'Bonjour, pouvez-vous m’envoyer la version signée avant jeudi ? J’en ai besoin pour préparer la rencontre. Si elle n’est pas prête, merci de m’indiquer la date prévue.',
    phrases: [
      'Pourriez-vous… ? — Could you…?',
      'Je voudrais… — I would like…',
      'Je peux le faire demain.',
    ],
    exercise: 'Demandez à un collègue de vérifier un tableau avant midi.',
    modelAnswer:
        'Pouvez-vous vérifier ce tableau avant midi, s’il vous plaît ? Je dois l’envoyer cet après-midi.',
    questions: [
      CourseQuestion(
        'Vous pouvez ___ le formulaire.',
        ['envoyer', 'envoyez', 'envoyé'],
        0,
        'Après pouvez, le verbe reste à l’infinitif.',
      ),
      CourseQuestion(
        'Quelle demande précise l’action et le délai ?',
        [
          'Le tableau, merci.',
          'Pouvez-vous vérifier le tableau avant midi ?',
          'Faites cela bientôt.',
        ],
        1,
        'L’action vérifier et le délai avant midi sont explicites.',
      ),
    ],
    speakingTask:
        'Demandez un document avec un délai précis. Votre partenaire vous dit qu’il n’est pas disponible : convenez d’une autre date ou d’une autre solution simple.',
    criteria: [
      'Ma demande est polie et précise.',
      'J’ai indiqué le délai.',
      'J’ai répondu à une contrainte concrète.',
    ],
  ),
  CourseLesson(
    id: 'ab-08-instructions',
    module: 4,
    foundation: true,
    title: 'Expliquer une procédure',
    objective: 'Donner des instructions ordonnées avec des verbes d’action.',
    teaching: [
      'À l’impératif, le sujet n’est pas écrit : « ouvrez le formulaire », « vérifiez la date ». Avec vous, les formes sont souvent celles du présent, sans vous. Quelques formes sont particulières : soyez, ayez.',
      'D’abord, ensuite et enfin organisent une suite d’étapes. Utilisez un verbe d’action pour chaque étape : ouvrir, remplir, signer, envoyer. Évitez une longue phrase avec plusieurs actions cachées.',
      'Une instruction négative complète garde ne… pas : « ne fermez pas la fenêtre ». Dans un document, l’infinitif peut aussi servir de consigne : « vérifier les coordonnées ». Restez cohérent dans votre liste.',
      'Expliquez comment savoir que la procédure est terminée : un message de confirmation ou une copie envoyée. Pour vérifier la compréhension, demandez la prochaine étape plutôt que seulement « compris ? ».',
    ],
    simpleExample: 'Il faut remplir et envoyer et vérifier.',
    developedExample:
        'D’abord, ouvrez le formulaire. Ensuite, vérifiez votre adresse et signez la dernière page. Enfin, envoyez le document au service indiqué. Gardez le message de confirmation.',
    phrases: [
      'D’abord… Ensuite… Enfin…',
      'N’oubliez pas de…',
      'Quelle est la prochaine étape ?',
    ],
    exercise:
        'Donnez trois consignes pour réserver une salle : choisir une date, vérifier la disponibilité, confirmer.',
    modelAnswer:
        'Choisissez une date. Vérifiez ensuite la disponibilité de la salle. Enfin, confirmez la réservation.',
    questions: [
      CourseQuestion(
        'Quelle forme donne une instruction à vous ?',
        ['Vous vérifier.', 'Vérifiez la date.', 'Vérifie vous la date.'],
        1,
        'Vérifiez est l’impératif correspondant à vous.',
      ),
      CourseQuestion(
        'Quel mot annonce la dernière étape ?',
        ['Enfin', 'D’abord', 'Hier'],
        0,
        'Enfin indique ici la dernière étape de la procédure.',
      ),
    ],
    speakingTask:
        'Expliquez en trois ou quatre étapes comment effectuer une tâche simple. Votre partenaire reformule les étapes; corrigez une omission éventuelle.',
    criteria: [
      'Mes étapes suivent un ordre logique.',
      'J’ai utilisé des verbes d’action.',
      'J’ai vérifié la compréhension de la procédure.',
    ],
  ),
  CourseLesson(
    id: 'ab-09-past',
    module: 5,
    foundation: true,
    title: 'Rapporter une action terminée',
    objective: 'Raconter des actions concrètes au passé composé.',
    teaching: [
      'Le passé composé se forme avec un auxiliaire au présent et un participe passé : j’ai préparé, nous avons fini. Les participes réguliers courants sont -é pour -er et -i pour beaucoup de verbes en -ir.',
      'Des participes fréquents sont irréguliers : fait, pris, reçu, écrit, vu. Apprenez-les dans une phrase utile : « j’ai reçu le message » plutôt qu’en liste isolée.',
      'Certains verbes utilisent être : « elle est arrivée », « ils sont partis ». Avec être, le participe s’accorde généralement avec le sujet dans ces exemples. Avec avoir, on ne l’accorde pas simplement parce que le sujet est féminin.',
      'Hier, ce matin et la semaine dernière situent les actions. Donnez ensuite le résultat concret : « j’ai envoyé le dossier; le service a confirmé la réception ».',
    ],
    simpleExample: 'Hier, je fais le rapport.',
    developedExample:
        'Hier, j’ai terminé le rapport et je l’ai envoyé à mon équipe. Nous avons reçu deux commentaires. J’ai corrigé le tableau avant la réunion.',
    phrases: ['Hier, j’ai…', 'Nous avons reçu…', 'Elle est arrivée…'],
    exercise:
        'Mettez au passé : « Je prépare la note et nous recevons une réponse. »',
    modelAnswer: 'J’ai préparé la note et nous avons reçu une réponse.',
    questions: [
      CourseQuestion(
        'Hier, nous ___ le document.',
        ['avons envoyé', 'envoyer', 'envoie'],
        0,
        'Avons + envoyé forme le passé composé.',
      ),
      CourseQuestion(
        'Léa est ___ à neuf heures.',
        ['arriver', 'arrivé', 'arrivée'],
        2,
        'Avec être, arrivée s’accorde ici avec Léa.',
      ),
    ],
    speakingTask:
        'Racontez trois actions réalisées hier ou dans une journée fictive. Indiquez le résultat de la dernière action, puis répondez à une question factuelle.',
    criteria: [
      'J’ai situé les actions dans le passé.',
      'J’ai utilisé un auxiliaire et un participe.',
      'J’ai expliqué un résultat concret.',
    ],
  ),
  CourseLesson(
    id: 'ab-10-background',
    module: 5,
    foundation: true,
    title: 'Donner le contexte d’un événement',
    objective:
        'Utiliser l’imparfait pour le contexte et le passé composé pour un événement.',
    teaching: [
      'L’imparfait décrit souvent un contexte ou une habitude passée : « le bureau était fermé », « nous travaillions ensemble ». Il ne signifie pas simplement que l’action était longue.',
      'Pour le former, prenez généralement la forme nous du présent, retirez -ons, puis ajoutez -ais, -ais, -ait, -ions, -iez, -aient. Être utilise le radical ét- : j’étais, nous étions.',
      'Le passé composé peut présenter un événement dans ce contexte : « nous préparions la salle quand le téléphone a sonné ». Les deux temps jouent des rôles différents dans le récit.',
      'Pour commencer, limitez votre récit à un contexte, un événement et une action. Vous n’avez pas besoin d’un récit compliqué pour transmettre les faits clairement.',
    ],
    simpleExample: 'Nous travaillons. Le téléphone sonne hier.',
    developedExample:
        'Nous préparions la réunion quand le téléphone a sonné. Une collègue était malade. J’ai donc modifié la liste des participants et prévenu l’accueil.',
    phrases: ['Nous étions…', 'Pendant que…', '… quand le téléphone a sonné.'],
    exercise:
        'Reliez le contexte « je préparais la salle » et l’événement « le groupe est arrivé ».',
    modelAnswer: 'Je préparais la salle quand le groupe est arrivé.',
    questions: [
      CourseQuestion(
        'Avant, nous ___ au deuxième étage.',
        ['travaillions', 'travailler', 'travaillerons'],
        0,
        'Travaillions situe ici une situation habituelle passée.',
      ),
      CourseQuestion(
        'Dans « il pleuvait quand je suis parti », le contexte est…',
        ['mon départ', 'la pluie', 'un projet futur'],
        1,
        'Il pleuvait installe le contexte du départ.',
      ),
    ],
    speakingTask:
        'Racontez un petit changement dans votre journée. Présentez ce qui se passait, ce qui est arrivé et ce que vous avez fait ensuite.',
    criteria: [
      'J’ai donné le contexte.',
      'J’ai distingué l’événement du contexte.',
      'L’ordre des faits est compréhensible.',
    ],
  ),
  CourseLesson(
    id: 'ab-11-future',
    module: 6,
    foundation: true,
    title: 'Présenter un projet concret',
    objective: 'Parler d’une action prévue et préciser qui fera quoi.',
    teaching: [
      'Aller au présent + infinitif exprime un projet : « je vais appeler », « nous allons préparer ». Les formes sont vais, vas, va, allons, allez, vont.',
      'Le futur simple présente aussi des actions à venir : « je préparerai », « nous enverrons ». Ses terminaisons sont -ai, -as, -a, -ons, -ez, -ont; certains radicaux sont irréguliers, comme ser-, aur- et fer-.',
      'Le choix entre futur proche et futur simple ne se réduit pas au nombre de jours. Pour cette classe, utilisez surtout une forme correcte avec un repère temporel clair.',
      'Un plan concret indique l’action, la personne responsable et le moment prévu. Distinguez ce qui est confirmé de ce qui reste à confirmer; ne présentez pas une intention comme une action déjà faite.',
    ],
    simpleExample: 'Nous faisons le projet bientôt.',
    developedExample:
        'Demain, je vais vérifier les inscriptions. Ma collègue préparera les documents jeudi. Nous confirmerons la salle vendredi, après la réponse du service.',
    phrases: ['Je vais…', 'Nous ferons…', 'Cela reste à confirmer.'],
    exercise:
        'Présentez deux tâches prévues demain avec deux responsables différents.',
    modelAnswer:
        'Demain, je vais appeler les participants. Nadia préparera la salle.',
    questions: [
      CourseQuestion(
        'Nous allons ___ les invitations.',
        ['envoyons', 'envoyer', 'envoyé'],
        1,
        'Le deuxième verbe est à l’infinitif après allons.',
      ),
      CourseQuestion(
        '« Cela reste à confirmer » signifie…',
        [
          'que tout est déjà terminé',
          'que le projet est annulé',
          'qu’une confirmation manque encore',
        ],
        2,
        'L’information n’est pas encore confirmée.',
      ),
    ],
    speakingTask:
        'Présentez un petit plan pour la semaine prochaine : trois tâches, leurs responsables et leurs dates. Répondez à une question sur une étape encore à confirmer.',
    criteria: [
      'J’ai situé les actions dans l’avenir.',
      'J’ai précisé les responsabilités.',
      'J’ai distingué le confirmé du non confirmé.',
    ],
  ),
  CourseLesson(
    id: 'ab-12-reasons',
    module: 6,
    foundation: true,
    title: 'Comparer et donner une raison',
    objective:
        'Expliquer un choix concret avec une comparaison et un lien logique.',
    teaching: [
      'Plus… que, moins… que et aussi… que permettent de comparer : « cette salle est plus grande que l’autre ». Comparez la même caractéristique pour les deux objets.',
      'Parce que introduit une raison : « je choisis cette salle parce qu’elle est disponible ». Donc introduit une conséquence : « elle est occupée, donc nous changeons de salle ».',
      'Mais ajoute une limite ou une différence : « le trajet est court, mais le bus est peu fréquent ». Une raison concrète suffit pour commencer; vous n’avez pas à débattre d’un sujet abstrait.',
      'Bon et meilleur décrivent souvent un nom; bien et mieux décrivent souvent la manière de faire : « un meilleur outil », « l’outil fonctionne mieux ». Utilisez un exemple familier pour vérifier le sens.',
    ],
    simpleExample: 'Je prends cette salle. Elle est bien.',
    developedExample:
        'Je choisis la salle B parce qu’elle est plus grande que la salle A. Elle est aussi plus proche de l’entrée. Elle n’a pas d’écran, donc je vais apporter un ordinateur.',
    phrases: ['Plus… que…', 'Je choisis… parce que…', '… donc…'],
    exercise:
        'Comparez deux trajets : A dure vingt minutes, B dure trente minutes mais coûte moins cher.',
    modelAnswer:
        'Le trajet A est plus rapide que le trajet B. Le trajet B est moins cher. Je choisis A parce que je dois arriver tôt.',
    questions: [
      CourseQuestion(
        'Parce que introduit…',
        ['une raison', 'une date', 'une personne'],
        0,
        'Parce que explique la cause ou la raison.',
      ),
      CourseQuestion(
        'L’outil fonctionne ___ maintenant.',
        ['meilleur', 'bonne', 'mieux'],
        2,
        'Mieux modifie fonctionne.',
      ),
    ],
    speakingTask:
        'Choisissez entre deux salles ou deux horaires. Comparez deux caractéristiques et expliquez votre choix avec une raison concrète.',
    criteria: [
      'J’ai comparé une même caractéristique.',
      'J’ai donné une raison liée au choix.',
      'J’ai utilisé un lien logique correct.',
    ],
  ),
  CourseLesson(
    id: 'ab-13-email',
    module: 7,
    foundation: true,
    title: 'Lire un courriel et répondre',
    objective:
        'Repérer l’action demandée, le responsable et le délai dans un message factuel.',
    teaching: [
      'Lisez d’abord l’objet et cherchez la demande principale. Puis relevez qui doit agir, ce qui doit être fait et avant quand. Une information secondaire ne doit pas cacher le délai.',
      'Dans votre réponse, annoncez rapidement votre action : « je confirme », « je vous envoie », « il me manque ». Utilisez une phrase pour chaque information importante.',
      'Une réponse courte peut être professionnelle : salutation, message, remerciement et nom. Adaptez la formule de politesse à la relation; vous n’avez pas besoin d’une formule très longue.',
      'Relisez les noms, dates, pièces jointes et négations. Une petite faute qui change une date ou transforme un refus en accord peut gêner davantage qu’une phrase simple.',
    ],
    simpleExample: 'Bonjour, oui. Merci.',
    developedExample:
        'Bonjour, je confirme ma présence à la rencontre de jeudi. Je vous enverrai le tableau mercredi avant midi. Il me manque seulement le numéro de salle. Merci, Sam.',
    phrases: [
      'Je confirme…',
      'Vous trouverez… en pièce jointe.',
      'Il me manque…',
    ],
    exercise:
        'Répondez à une demande de disponibilité pour vendredi : vous êtes libre seulement le matin.',
    modelAnswer:
        'Bonjour, je suis disponible vendredi matin, mais pas l’après-midi. Une rencontre à dix heures vous convient-elle ? Merci.',
    questions: [
      CourseQuestion(
        'Que faut-il repérer en priorité dans une demande ?',
        [
          'La longueur du message',
          'L’action et le délai',
          'Le nombre d’adjectifs',
        ],
        1,
        'L’action et le délai permettent de répondre correctement.',
      ),
      CourseQuestion(
        'Quelle réponse précise une disponibilité ?',
        [
          'Oui, peut-être tout.',
          'Bonjour, merci.',
          'Je suis disponible vendredi matin.',
        ],
        2,
        'La réponse indique un moment précis.',
      ),
    ],
    speakingTask:
        'Expliquez oralement le contenu d’un court courriel fictif, puis dites ce que vous allez répondre. Votre partenaire vous demande une précision sur le délai.',
    criteria: [
      'J’ai identifié la demande principale.',
      'J’ai précisé le délai ou la disponibilité.',
      'Ma réponse apporte le renseignement demandé.',
    ],
  ),
  CourseLesson(
    id: 'ab-14-clarify',
    module: 7,
    foundation: true,
    title: 'Écouter et demander une clarification',
    objective:
        'Comprendre un message concret et vérifier un détail sans prétendre avoir compris.',
    teaching: [
      'À la première écoute, cherchez le sujet général. À la deuxième, notez les personnes, les actions et les moments importants. Il n’est pas nécessaire de transcrire chaque mot.',
      'Utilisez « pouvez-vous répéter la dernière information ? » ou « que signifie ce mot ? ». Une demande ciblée aide davantage qu’un simple « quoi ? ».',
      'Reformulez avec vos propres mots : « donc, je dois appeler avant midi ». Votre interlocuteur peut ainsi corriger un malentendu avant que vous agissiez.',
      'Un mot inconnu ne rend pas tout le message incompréhensible. Utilisez le contexte, mais vérifiez si ce mot change l’action attendue. Ne devinez pas une heure ou un nom important.',
    ],
    simpleExample: 'Oui, oui. Je pense que j’ai compris.',
    developedExample:
        'J’ai compris que la livraison arrive demain. Pouvez-vous répéter le numéro de salle ? Merci. Donc, je dois déposer les boîtes dans la salle 210 avant dix heures.',
    phrases: [
      'Pouvez-vous parler un peu plus lentement ?',
      'Que signifie… ?',
      'Donc, si je comprends bien…',
    ],
    exercise:
        'Vous avez compris la tâche mais pas le délai. Demandez seulement l’information manquante.',
    modelAnswer:
        'J’ai compris que je dois vérifier le dossier. Pour quelle date devez-vous recevoir ma réponse ?',
    questions: [
      CourseQuestion(
        'Une heure importante est incertaine. Je dois…',
        ['deviner', 'l’ignorer', 'demander confirmation'],
        2,
        'Vérifier évite une erreur dans l’action à effectuer.',
      ),
      CourseQuestion(
        'Quelle demande est ciblée ?',
        [
          'Pouvez-vous répéter le numéro de salle ?',
          'Je ne comprends rien du tout.',
          'Oui, tout est clair.',
        ],
        0,
        'Elle indique précisément le renseignement manquant.',
      ),
    ],
    speakingTask:
        'Demandez à votre partenaire une consigne courte avec un lieu et une heure. Reformulez la tâche et demandez une précision sur un détail.',
    criteria: [
      'J’ai retenu le sens général.',
      'J’ai demandé une précision utile.',
      'J’ai reformulé l’action attendue.',
    ],
  ),
  CourseLesson(
    id: 'ab-15-incident',
    module: 8,
    foundation: true,
    title: 'Expliquer un problème et une solution',
    objective:
        'Présenter une situation moins habituelle avec des faits et une prochaine étape.',
    teaching: [
      'Pour expliquer un problème, dites ce qui était prévu, ce qui s’est passé et ce que vous avez fait. Gardez un ordre facile à suivre avec d’abord, puis et finalement.',
      'Distinguez l’observation de la supposition : « le fichier ne s’ouvre pas » est un fait; « le logiciel est probablement en cause » est une hypothèse à vérifier. Au niveau B, restez dans une situation concrète.',
      'Nommez clairement la personne ou l’objet avant de reprendre par il, elle, le ou la. Si deux dossiers sont mentionnés, répétez le nom pour éviter une confusion.',
      'Terminez par une action réalisable : qui va vérifier, quand et comment la personne sera informée. Vous expliquez la suite au lieu de rester seulement sur le problème.',
    ],
    simpleExample: 'Le fichier ne marche pas. C’est un problème.',
    developedExample:
        'Ce matin, je devais envoyer le tableau, mais le fichier ne s’ouvrait pas. J’ai demandé une nouvelle copie à ma collègue. Je vais la vérifier avant midi et vous confirmer la réception.',
    phrases: [
      'Ce qui était prévu…',
      'Le problème est que…',
      'La prochaine étape consiste à…',
    ],
    exercise:
        'Expliquez une salle réservée mais occupée : indiquez le problème et une solution concrète.',
    modelAnswer:
        'La salle était réservée pour notre équipe, mais un autre groupe l’occupe. J’ai trouvé une autre salle. Je vais envoyer le nouveau lieu aux participants.',
    questions: [
      CourseQuestion(
        'Quel énoncé décrit directement une observation ?',
        [
          'Le fichier ne s’ouvre pas.',
          'Le système est forcément mal conçu.',
          'Tout échouera.',
        ],
        0,
        'Il décrit ce que la personne constate sans cause inventée.',
      ),
      CourseQuestion(
        'Une prochaine étape utile précise…',
        [
          'seulement un sentiment',
          'une action et un responsable',
          'tous les problèmes anciens',
        ],
        1,
        'Une action et un responsable rendent la suite concrète.',
      ),
    ],
    speakingTask:
        'Racontez un petit incident au travail : situation prévue, problème, action effectuée et suite prévue. Répondez à deux questions factuelles de votre partenaire.',
    criteria: [
      'Le déroulement des faits est clair.',
      'J’ai distingué le fait de la supposition.',
      'J’ai expliqué la prochaine étape.',
    ],
  ),
  CourseLesson(
    id: 'ab-16-transfer',
    module: 8,
    foundation: true,
    title: 'Bilan : mener un échange factuel',
    objective:
        'Combiner questions, description, récit et plan dans une situation nouvelle mais concrète.',
    teaching: [
      'Le bilan reprend les outils du parcours dans une seule situation. Préparez quelques mots-clés, pas un texte à réciter. Vous devez pouvoir répondre à une question qui n’était pas prévue.',
      'Présentez la situation au présent, racontez une action passée et expliquez une étape future. Des phrases simples bien reliées suffisent; la complexité n’est pas un objectif en soi.',
      'Vérifiez les détails importants et demandez une clarification si nécessaire. Une pause ou un accent ne prouve pas à lui seul un échec. L’important est que le message concret reste compréhensible.',
      'Après l’essai, choisissez deux points à retravailler. Les résultats de cette classe décrivent des activités réalisées, pas une certification B. Passez au parcours B → C progressivement tout en gardant les rappels utiles.',
    ],
    simpleExample:
        'Je connais des phrases, mais je ne peux pas expliquer la situation.',
    developedExample:
        'Nous accueillons huit collègues lundi. J’ai réservé une salle hier, mais il manque deux chaises. Je vais contacter l’accueil ce matin. Pouvez-vous confirmer l’heure d’arrivée du groupe ?',
    phrases: ['Voici la situation…', 'J’ai déjà…', 'Il reste à…'],
    exercise:
        'Préparez trois mots-clés pour organiser une rencontre après un changement d’horaire.',
    modelAnswer:
        'Horaire, salle, participants. La rencontre commence maintenant à dix heures. J’ai vérifié la salle; je vais prévenir les participants.',
    questions: [
      CourseQuestion(
        'Quel objectif correspond au travail vers B dans ce bilan ?',
        [
          'Débattre uniquement de concepts abstraits',
          'Expliquer une situation concrète et répondre aux questions',
          'Réciter un texte sans relance',
        ],
        1,
        'B vise notamment une communication factuelle dans des situations concrètes.',
      ),
      CourseQuestion(
        'Terminer le parcours signifie…',
        [
          'avoir réalisé les activités, sans certification officielle',
          'avoir automatiquement obtenu BBB',
          'ne plus devoir pratiquer',
        ],
        0,
        'Seule une évaluation officielle peut attribuer le résultat officiel.',
      ),
    ],
    speakingTask:
        'Organisez l’accueil d’un groupe après un changement de salle. Décrivez la situation, expliquez ce que vous avez déjà fait et ce qui reste à faire. Demandez un renseignement manquant et répondez aux relances factuelles.',
    criteria: [
      'J’ai relié présent, passé et futur clairement.',
      'J’ai répondu à des questions sans réciter.',
      'J’ai identifié deux points personnels à reprendre.',
    ],
  ),
];
