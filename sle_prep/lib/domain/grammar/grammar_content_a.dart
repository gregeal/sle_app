/// Units 1 and 2 of the grammar path: the present, the sentence around it,
/// and the two futures.
library;

import '../course/course_catalog.dart' show CourseQuestion;
import 'grammar_course.dart';

const _subjects = 'il / elle / on';

const grammarLessonsA = <GrammarLesson>[
  GrammarLesson(
    id: 'g01-etre-avoir',
    unit: 1,
    title: 'Être et avoir au présent',
    summary: 'Dire qui vous êtes, où vous êtes et ce que vous avez.',
    englishKey:
        'Être = to be, avoir = to have. Both are irregular, and every '
        'compound tense is built on them, so they come first.',
    whenToUse: [
      'Être : identité, profession, lieu, état. « Je suis analyste. » '
          '« Elle est à Ottawa. »',
      'Avoir : possession, âge et plusieurs expressions. « J’ai une '
          'réunion. » « Il a trente ans. »',
      'En français, on « a » faim, soif, chaud, froid, raison, besoin : '
          '« J’ai besoin d’aide. »',
    ],
    howToForm: [
      'Ces deux verbes sont irréguliers : il faut les connaître par cœur.',
      'Devant une voyelle, je devient j’ : j’ai.',
      'La profession se dit sans article : « Je suis gestionnaire. »',
    ],
    tables: [
      GrammarTable('être', [
        'je|suis',
        'tu|es',
        '$_subjects|est',
        'nous|sommes',
        'vous|êtes',
        'ils / elles|sont',
      ]),
      GrammarTable('avoir', [
        'j’|ai',
        'tu|as',
        '$_subjects|a',
        'nous|avons',
        'vous|avez',
        'ils / elles|ont',
      ]),
    ],
    examples: [
      'Je suis agente de programme.|I am a program officer.',
      'Nous sommes en réunion jusqu’à midi.|We are in a meeting until noon.',
      'J’ai deux dossiers urgents.|I have two urgent files.',
      'Vous avez raison.|You are right.',
      'Ils ont besoin d’une réponse aujourd’hui.|They need an answer today.',
    ],
    pitfalls: [
      'Je suis 35 ans.|J’ai 35 ans.|L’âge se dit avec avoir.',
      'Je suis un analyste.|Je suis analyste.|Pas d’article devant une '
          'profession après être.',
      'Ils sont raison.|Ils ont raison.|Avoir raison, avoir tort, avoir '
          'besoin.',
    ],
    questions: [
      CourseQuestion(
        'Nous ___ en retard pour la réunion.',
        ['avons', 'sommes', 'êtes', 'sont'],
        1,
        'Être en retard, avec nous : nous sommes.',
      ),
      CourseQuestion(
        'Elle ___ beaucoup d’expérience.',
        ['est', 'as', 'a', 'ont'],
        2,
        'Avoir de l’expérience : elle a.',
      ),
      CourseQuestion(
        'Quel âge ___-vous ?',
        ['êtes', 'avez', 'as', 'sont'],
        1,
        'L’âge se dit avec avoir : quel âge avez-vous ?',
      ),
      CourseQuestion(
        'Les documents ___ sur votre bureau.',
        ['sont', 'ont', 'est', 'a'],
        0,
        'Un lieu se dit avec être; le sujet est pluriel : sont.',
      ),
    ],
    sayAloud: [
      'Présentez-vous : nom, poste, ville.|Je m’appelle Alex. Je suis '
          'analyste. Je suis à Ottawa.',
      'Dites deux choses que vous avez au travail aujourd’hui.|J’ai une '
          'réunion à dix heures et j’ai un rapport à finir.',
      'Dites de quoi votre équipe a besoin.|Mon équipe a besoin de plus de '
          'temps.',
    ],
    drillTopics: ['etre_avoir'],
    referencePages: ['virr1|Être', 'virr2|Avoir'],
    conjugationVerb: 'etre',
    videoQuery: 'être et avoir présent',
  ),
  GrammarLesson(
    id: 'g02-articles',
    unit: 1,
    title: 'Les articles et le genre',
    summary: 'Choisir le, la, un, une, du, des sans hésiter.',
    englishKey:
        'Every French noun is masculine or feminine and almost always needs '
        'an article. Learn each new noun together with its article.',
    whenToUse: [
      'Le, la, l’, les : une chose précise ou connue. « Le rapport est '
          'prêt. »',
      'Un, une, des : une chose non précisée. « J’ai une question. »',
      'Du, de la, de l’ : une quantité qu’on ne compte pas. « J’ai du '
          'travail. »',
    ],
    howToForm: [
      'À + le = au, à + les = aux : « Je parle au directeur. »',
      'De + le = du, de + les = des : « le bureau du directeur ».',
      'Après une négation, un, une, du, des deviennent de : « Je n’ai pas '
          'de question. »',
      'Devant une voyelle : l’ (l’équipe) et d’ (pas d’expérience).',
    ],
    tables: [
      GrammarTable('Les articles', [
        'masculin|le · un · du',
        'féminin|la · une · de la',
        'devant une voyelle|l’ · un / une · de l’',
        'pluriel|les · des · des',
      ]),
      GrammarTable('Les contractions', [
        'à + le|au',
        'à + les|aux',
        'de + le|du',
        'de + les|des',
      ]),
    ],
    examples: [
      'La réunion commence à neuf heures.|The meeting starts at nine.',
      'J’ai un rendez-vous avec la directrice.|I have an appointment with '
          'the director.',
      'Nous avons du temps cet après-midi.|We have some time this afternoon.',
      'Je parle aux employés du ministère.|I am speaking to the '
          'department’s employees.',
      'Il n’y a pas de problème.|There is no problem.',
    ],
    pitfalls: [
      'Je parle à le gestionnaire.|Je parle au gestionnaire.|À + le se '
          'contracte toujours en au.',
      'Je n’ai pas une réponse.|Je n’ai pas de réponse.|Après pas, un, une, '
          'des deviennent de.',
      'J’aime travail d’équipe.|J’aime le travail d’équipe.|Un nom a presque '
          'toujours besoin d’un article.',
    ],
    questions: [
      CourseQuestion(
        'Je travaille ___ ministère des Finances.',
        ['à le', 'au', 'aux', 'à la'],
        1,
        'À + le ministère = au ministère.',
      ),
      CourseQuestion(
        'Elle n’a pas ___ ordinateur.',
        ['un', 'de', 'd’', 'des'],
        2,
        'Après la négation : de, qui devient d’ devant une voyelle.',
      ),
      CourseQuestion(
        '___ équipe est très occupée cette semaine.',
        ['Le', 'La', 'L’', 'Les'],
        2,
        'Devant une voyelle, le et la deviennent l’.',
      ),
      CourseQuestion(
        'C’est le bureau ___ directeurs.',
        ['de les', 'du', 'des', 'de'],
        2,
        'De + les = des.',
      ),
    ],
    sayAloud: [
      'Dites où vous travaillez et à qui vous parlez souvent.|Je travaille '
          'au ministère. Je parle souvent aux analystes et à la gestionnaire.',
      'Dites une chose que vous avez et une chose que vous n’avez pas.|J’ai '
          'un ordinateur portable, mais je n’ai pas de bureau fermé.',
      'Décrivez votre équipe en deux phrases.|L’équipe est petite. Les '
          'collègues sont sympathiques.',
    ],
    referencePages: [
      'det2|Articles définis',
      'det4|Articles indéfinis',
      'det5|Articles partitifs',
    ],
    videoQuery: 'articles définis indéfinis partitifs',
  ),
  GrammarLesson(
    id: 'g03-present-er',
    unit: 1,
    title: 'Le présent des verbes en -er',
    summary: 'Décrire ce que vous faites tous les jours.',
    englishKey:
        'One French present tense covers "I work", "I am working" and "I do '
        'work". There is no separate -ing form.',
    whenToUse: [
      'Une habitude : « Je travaille à distance le lundi. »',
      'Une action en cours : « Je prépare la réunion. »',
      'Un fait général : « Le service ferme à dix-sept heures. »',
    ],
    howToForm: [
      'Enlevez -er et ajoutez : -e, -es, -e, -ons, -ez, -ent.',
      'Les terminaisons -e, -es, -ent ne se prononcent pas : parle, parles '
          'et parlent se disent de la même façon.',
      'Verbes en -ger et en -cer : nous mangeons, nous commençons.',
      'Avec depuis, on garde le présent : « Je travaille ici depuis trois '
          'ans. »',
    ],
    tables: [
      GrammarTable('parler', [
        'je|parle',
        'tu|parles',
        '$_subjects|parle',
        'nous|parlons',
        'vous|parlez',
        'ils / elles|parlent',
      ]),
    ],
    examples: [
      'Je travaille au centre-ville.|I work downtown.',
      'Nous préparons le rapport trimestriel.|We are preparing the quarterly '
          'report.',
      'Vous parlez très bien français.|You speak French very well.',
      'Ils commencent à huit heures trente.|They start at eight thirty.',
      'J’habite à Ottawa depuis cinq ans.|I have lived in Ottawa for five '
          'years.',
    ],
    pitfalls: [
      'Je suis travaille.|Je travaille.|On ne met pas être devant le verbe '
          'pour dire "I am working".',
      'Ils parle français.|Ils parlent français.|À l’écrit, ils et elles '
          'prennent -ent, même si on ne l’entend pas.',
      'J’ai travaillé ici depuis 2020.|Je travaille ici depuis 2020.|Une '
          'action qui continue encore : présent + depuis.',
    ],
    questions: [
      CourseQuestion(
        'Nous ___ les demandes chaque matin.',
        ['vérifie', 'vérifiez', 'vérifions', 'vérifient'],
        2,
        'Avec nous : -ons.',
      ),
      CourseQuestion(
        'Elles ___ au troisième étage.',
        ['travaille', 'travailles', 'travaillons', 'travaillent'],
        3,
        'Avec elles : -ent.',
      ),
      CourseQuestion(
        'Comment dit-on "I am preparing the meeting" ?',
        [
          'Je suis préparer la réunion.',
          'Je prépare la réunion.',
          'Je suis prépare la réunion.',
          'Je préparant la réunion.',
        ],
        1,
        'Le présent simple exprime aussi l’action en cours.',
      ),
      CourseQuestion(
        'Nous ___ le projet lundi.',
        ['commencons', 'commençons', 'commencez', 'commencent'],
        1,
        'Devant -ons, le c devient ç pour garder le son « s ».',
      ),
    ],
    sayAloud: [
      'Décrivez trois choses que vous faites chaque jour au travail.|Chaque '
          'jour, je vérifie mes courriels, je participe à une réunion et je '
          'prépare des documents.',
      'Dites depuis quand vous travaillez à votre poste.|Je travaille à ce '
          'poste depuis deux ans.',
      'Dites ce que votre équipe prépare cette semaine.|Cette semaine, nous '
          'préparons une présentation.',
    ],
    drillTopics: ['present_indicatif'],
    referencePages: ['tapr1|Le présent', 'ver1|Verbes en -er'],
    conjugationVerb: 'parler',
    videoQuery: 'présent verbes en er',
  ),
  GrammarLesson(
    id: 'g04-present-irreguliers',
    unit: 1,
    title: 'Le présent : -ir, -re et verbes irréguliers',
    summary:
        'Utiliser les verbes les plus fréquents : aller, faire, prendre, '
        'pouvoir, vouloir, devoir.',
    englishKey:
        'A handful of irregular verbs do most of the work in everyday '
        'French. They are worth memorising before anything else.',
    whenToUse: [
      'Les verbes en -ir comme finir et choisir, et en -re comme répondre '
          'et attendre, suivent un modèle régulier.',
      'Aller, faire, prendre, venir, pouvoir, vouloir et devoir sont '
          'irréguliers et très fréquents.',
      'Pouvoir, vouloir, devoir + infinitif : « Je dois partir. » '
          '« Pouvez-vous répéter ? »',
    ],
    howToForm: [
      'Finir : -is, -is, -it, -issons, -issez, -issent.',
      'Répondre : -s, -s, pas de terminaison, -ons, -ez, -ent.',
      'Après pouvoir, vouloir, devoir et aller, le deuxième verbe reste à '
          'l’infinitif.',
    ],
    tables: [
      GrammarTable('finir', [
        'je|finis',
        'tu|finis',
        '$_subjects|finit',
        'nous|finissons',
        'vous|finissez',
        'ils / elles|finissent',
      ]),
      GrammarTable('répondre', [
        'je|réponds',
        'tu|réponds',
        '$_subjects|répond',
        'nous|répondons',
        'vous|répondez',
        'ils / elles|répondent',
      ]),
      GrammarTable('Sept irréguliers (je · nous · ils)', [
        'aller|vais · allons · vont',
        'faire|fais · faisons · font',
        'prendre|prends · prenons · prennent',
        'venir|viens · venons · viennent',
        'pouvoir|peux · pouvons · peuvent',
        'vouloir|veux · voulons · veulent',
        'devoir|dois · devons · doivent',
      ]),
    ],
    examples: [
      'Je finis le rapport cet après-midi.|I am finishing the report this '
          'afternoon.',
      'Nous répondons aux courriels le jour même.|We answer emails the same '
          'day.',
      'Je vais au bureau trois jours par semaine.|I go to the office three '
          'days a week.',
      'Pouvez-vous m’envoyer le document ?|Can you send me the document?',
      'Vous devez remplir ce formulaire.|You must fill in this form.',
    ],
    pitfalls: [
      'Vous faisez une erreur.|Vous faites une erreur.|Faire : vous faites. '
          'Dire : vous dites.',
      'Je peux pas venir.|Je ne peux pas venir.|À l’écrit et à l’examen, '
          'gardez le ne.',
      'Je dois de partir.|Je dois partir.|Devoir, pouvoir et vouloir sont '
          'suivis de l’infinitif, sans préposition.',
    ],
    questions: [
      CourseQuestion(
        'Ils ___ une pause à dix heures.',
        ['prend', 'prenons', 'prennent', 'prenez'],
        2,
        'Prendre : ils prennent, avec deux n.',
      ),
      CourseQuestion(
        'Vous ___ beaucoup de progrès.',
        ['faisez', 'faites', 'faisons', 'font'],
        1,
        'Faire : vous faites.',
      ),
      CourseQuestion(
        'Nous ___ répondre avant vendredi.',
        ['devons', 'doivent', 'dois', 'devez'],
        0,
        'Devoir : nous devons, suivi de l’infinitif.',
      ),
      CourseQuestion(
        'Elle ___ toujours ses dossiers à temps.',
        ['finis', 'finit', 'finissent', 'finissons'],
        1,
        'Finir : elle finit.',
      ),
    ],
    sayAloud: [
      'Dites ce que vous devez faire aujourd’hui.|Aujourd’hui, je dois finir '
          'un rapport et je dois répondre à trois courriels.',
      'Demandez poliment de l’aide à un collègue.|Pouvez-vous m’aider avec '
          'ce dossier, s’il vous plaît ?',
      'Dites où vous allez après le travail.|Après le travail, je vais à la '
          'salle de sport, puis je rentre à la maison.',
    ],
    drillTopics: ['present_indicatif'],
    referencePages: [
      'vir1|Verbes en -ir',
      'vre1|Verbes en -re',
      'vm1|Pouvoir, vouloir, devoir',
    ],
    conjugationVerb: 'aller',
    videoQuery: 'présent verbes irréguliers aller faire prendre',
  ),
  GrammarLesson(
    id: 'g05-negation-questions',
    unit: 1,
    title: 'La négation et les questions',
    summary: 'Dire non et poser une question de trois façons.',
    englishKey:
        'Negation wraps the verb: ne … pas. A question can be made by '
        'intonation, with est-ce que, or by inversion, from casual to formal.',
    whenToUse: [
      'Ne … pas entoure le verbe conjugué : « Je ne comprends pas. »',
      'Autres négations : ne … jamais (never), ne … plus (no longer), '
          'ne … rien (nothing), ne … personne (nobody).',
      'Trois façons de poser une question : l’intonation (familier), '
          'est-ce que (courant), l’inversion (soutenu).',
    ],
    howToForm: [
      'Ne devient n’ devant une voyelle : « Je n’ai pas le temps. »',
      'Au passé composé, la négation entoure l’auxiliaire : « Je n’ai pas '
          'fini. »',
      'Avec deux verbes, elle entoure le premier : « Je ne peux pas '
          'venir. »',
      'Mot interrogatif + est-ce que : « Quand est-ce que la réunion '
          'commence ? »',
    ],
    tables: [
      GrammarTable('Trois façons de demander', [
        'intonation|Vous avez le rapport ?',
        'est-ce que|Est-ce que vous avez le rapport ?',
        'inversion|Avez-vous le rapport ?',
      ]),
      GrammarTable('Les mots interrogatifs', [
        'où|where',
        'quand|when',
        'comment|how',
        'pourquoi|why',
        'combien (de)|how much, how many',
        'qui|who',
        'qu’est-ce que|what',
        'quel / quelle|which, what',
      ]),
    ],
    examples: [
      'Je ne travaille pas le vendredi.|I do not work on Fridays.',
      'Nous n’avons plus de papier.|We have no more paper.',
      'Est-ce que vous pouvez répéter ?|Can you repeat?',
      'Pourquoi est-ce que le projet est en retard ?|Why is the project '
          'late?',
      'À quelle heure commence la formation ?|What time does the training '
          'start?',
    ],
    pitfalls: [
      'Je pas comprends.|Je ne comprends pas.|Ne avant le verbe, pas après.',
      'Je n’ai pas rien reçu.|Je n’ai rien reçu.|Rien, jamais, plus et '
          'personne remplacent pas.',
      'Quoi vous voulez ?|Qu’est-ce que vous voulez ?|Au début d’une '
          'question, "what" se dit qu’est-ce que.',
    ],
    questions: [
      CourseQuestion(
        'Choisissez la phrase correcte.',
        [
          'Je ne suis pas d’accord.',
          'Je suis ne pas d’accord.',
          'Je ne pas suis d’accord.',
          'Je suis pas ne d’accord.',
        ],
        0,
        'Ne + verbe + pas.',
      ),
      CourseQuestion(
        'Il ___ arrive ___ en retard. (never)',
        ['ne … pas', 'n’ … jamais', 'ne … rien', 'n’ … personne'],
        1,
        '"Never" se dit ne … jamais, et ne devient n’ devant une voyelle.',
      ),
      CourseQuestion(
        '___ vous avez reçu mon courriel ?',
        ['Est-ce que', 'Qu’est-ce que', 'Quel', 'Qui'],
        0,
        'Pour une question à réponse oui ou non : est-ce que.',
      ),
      CourseQuestion(
        'Au passé composé : « Je ___ fini. »',
        ['n’ai pas', 'ai ne pas', 'ne pas ai', 'n’ai rien pas'],
        0,
        'La négation entoure l’auxiliaire : je n’ai pas fini.',
      ),
    ],
    sayAloud: [
      'Dites deux choses que vous ne faites pas le week-end.|Le week-end, je '
          'ne travaille pas et je ne regarde jamais mes courriels.',
      'Posez deux questions à un nouveau collègue.|Où est-ce que vous '
          'travailliez avant ? Depuis quand est-ce que vous êtes à Ottawa ?',
      'Demandez l’heure et le lieu d’une réunion.|À quelle heure est la '
          'réunion ? Dans quelle salle est-ce qu’elle a lieu ?',
    ],
    referencePages: [
      'neg2|La négation',
      'int2|Questions oui / non',
      'int7|Mots interrogatifs',
    ],
    videoQuery: 'négation et interrogation',
  ),
  GrammarLesson(
    id: 'g06-adjectifs',
    unit: 1,
    title: 'L’accord et la place des adjectifs',
    summary: 'Décrire une personne, un projet ou un document correctement.',
    englishKey:
        'An adjective agrees with its noun in gender and number, and most '
        'adjectives come after the noun.',
    whenToUse: [
      'L’adjectif s’accorde avec le nom : féminin + e, pluriel + s.',
      'La plupart des adjectifs se placent après le nom : « un dossier '
          'urgent ».',
      'Quelques adjectifs courts et fréquents se placent avant : bon, '
          'mauvais, grand, petit, nouveau, jeune, vieux, beau, premier, '
          'dernier.',
    ],
    howToForm: [
      'Masculin → féminin : + e (important → importante). Un adjectif déjà '
          'terminé par -e ne change pas (difficile).',
      'Pluriel : + s (importants, importantes). Un adjectif déjà terminé '
          'par -s ou -x ne change pas.',
      '-if → -ive (actif, active), -eux → -euse (sérieux, sérieuse), '
          '-el → -elle (annuel, annuelle).',
      'Irréguliers : nouveau / nouvelle, beau / belle, vieux / vieille, '
          'bon / bonne.',
    ],
    tables: [
      GrammarTable('L’accord', [
        'masculin singulier|un rapport important',
        'féminin singulier|une réunion importante',
        'masculin pluriel|des rapports importants',
        'féminin pluriel|des réunions importantes',
      ]),
      GrammarTable('Changements fréquents', [
        'actif|active',
        'sérieux|sérieuse',
        'annuel|annuelle',
        'nouveau|nouvelle',
        'premier|première',
        'bon|bonne',
      ]),
    ],
    examples: [
      'C’est une décision difficile.|It is a difficult decision.',
      'Nous avons une nouvelle directrice.|We have a new director.',
      'Les résultats sont encourageants.|The results are encouraging.',
      'J’ai lu les dernières versions.|I read the latest versions.',
      'C’est une bonne idée.|That is a good idea.',
    ],
    pitfalls: [
      'une important réunion|une réunion importante|Féminin + e, et '
          'l’adjectif se place après le nom.',
      'Les employés sont satisfait.|Les employés sont satisfaits.|Après '
          'être aussi, l’adjectif s’accorde avec le sujet.',
      'un nouveau employé|un nouvel employé|Devant une voyelle au '
          'masculin : nouvel, bel, vieil.',
    ],
    questions: [
      CourseQuestion(
        'Une question ___ .',
        ['important', 'importante', 'importants', 'importantes'],
        1,
        'Question est féminin singulier : importante.',
      ),
      CourseQuestion(
        'Les nouvelles politiques sont ___ .',
        ['clair', 'claire', 'clairs', 'claires'],
        3,
        'Politiques est féminin pluriel : claires.',
      ),
      CourseQuestion(
        'Choisissez l’ordre correct.',
        [
          'un urgent dossier',
          'un dossier urgent',
          'urgent un dossier',
          'un dossier urgente',
        ],
        1,
        'Urgent se place après le nom, et dossier est masculin.',
      ),
      CourseQuestion(
        'Une employée très ___ .',
        ['sérieux', 'sérieuse', 'sérieuses', 'sérieuxe'],
        1,
        '-eux devient -euse au féminin.',
      ),
    ],
    sayAloud: [
      'Décrivez un collègue avec trois adjectifs.|Ma gestionnaire est '
          'organisée, patiente et très compétente.',
      'Décrivez un projet récent.|C’est un projet intéressant, mais les '
          'délais sont courts.',
      'Décrivez votre bureau.|J’ai un petit bureau lumineux avec une grande '
          'fenêtre.',
    ],
    drillTopics: ['adjectifs_accords'],
    referencePages: ['adj2|Formation et place des adjectifs'],
    videoQuery: 'accord et place des adjectifs',
  ),
  GrammarLesson(
    id: 'g07-pronominaux',
    unit: 1,
    title: 'Les verbes pronominaux',
    summary: 'Parler de votre routine : se lever, se préparer, s’occuper de.',
    englishKey:
        'A pronominal verb carries an extra pronoun that matches the '
        'subject: je me, tu te, il se, nous nous, vous vous, ils se.',
    whenToUse: [
      'L’action revient sur le sujet : « Je me lève à six heures. »',
      'Une action réciproque : « Nous nous parlons tous les jours. »',
      'Beaucoup de verbes courants sont pronominaux : s’appeler, se '
          'souvenir, s’occuper de, se rendre à, s’inscrire.',
    ],
    howToForm: [
      'Le pronom se place avant le verbe : je me prépare.',
      'Négation : ne + pronom + verbe + pas. « Je ne me souviens pas. »',
      'Avec un infinitif, le pronom suit le sujet : « Je vais me '
          'préparer. » « Nous devons nous inscrire. »',
      'Me, te, se deviennent m’, t’, s’ devant une voyelle.',
    ],
    tables: [
      GrammarTable('se lever', [
        'je|me lève',
        'tu|te lèves',
        '$_subjects|se lève',
        'nous|nous levons',
        'vous|vous levez',
        'ils / elles|se lèvent',
      ]),
    ],
    examples: [
      'Je me lève à six heures et demie.|I get up at six thirty.',
      'Elle s’occupe des nouveaux dossiers.|She takes care of the new files.',
      'Nous nous réunissons chaque lundi.|We meet every Monday.',
      'Je ne me souviens pas de son nom.|I do not remember his name.',
      'Vous devez vous inscrire avant vendredi.|You must register before '
          'Friday.',
    ],
    pitfalls: [
      'Je lève à six heures.|Je me lève à six heures.|Sans me, lever veut '
          'dire lever quelque chose.',
      'Nous devons s’inscrire.|Nous devons nous inscrire.|Le pronom suit le '
          'sujet, même devant un infinitif.',
      'Je me ne souviens pas.|Je ne me souviens pas.|Ne se place avant le '
          'pronom.',
    ],
    questions: [
      CourseQuestion(
        'Je ___ à sept heures.',
        ['lève', 'me lève', 'se lève', 'me lèves'],
        1,
        'Avec je : me lève.',
      ),
      CourseQuestion(
        'Nous ___ chaque mardi.',
        [
          'se réunissons',
          'nous réunissons',
          'réunissons nous',
          'nous réunissent',
        ],
        1,
        'Avec nous, le pronom est nous : nous nous réunissons.',
      ),
      CourseQuestion(
        'Vous devez ___ avant le 15.',
        ['s’inscrire', 'vous inscrire', 'vous inscrivez', 'inscrire vous'],
        1,
        'Le pronom suit le sujet : vous devez vous inscrire.',
      ),
      CourseQuestion(
        'Choisissez la forme négative correcte.',
        [
          'Je me ne souviens pas.',
          'Je ne me souviens pas.',
          'Je ne souviens me pas.',
          'Je me souviens ne pas.',
        ],
        1,
        'Ne + pronom + verbe + pas.',
      ),
    ],
    sayAloud: [
      'Décrivez votre matin avant le travail.|Je me lève à six heures, je me '
          'prépare et je me rends au bureau en autobus.',
      'Dites de quoi vous vous occupez au travail.|Je m’occupe des demandes '
          'de renseignements.',
      'Dites quand votre équipe se réunit.|Nous nous réunissons le lundi '
          'matin et le jeudi après-midi.',
    ],
    drillTopics: ['verbes_pronominaux'],
    referencePages: ['vpr1|Verbes pronominaux'],
    conjugationVerb: 'se-lever',
    videoQuery: 'verbes pronominaux présent',
  ),
  GrammarLesson(
    id: 'g08-futur-proche',
    unit: 2,
    title: 'Le futur proche',
    summary: 'Dire ce que vous allez faire bientôt.',
    englishKey:
        'Aller in the present + an infinitive means "going to". It is the '
        'everyday way to talk about the future.',
    whenToUse: [
      'Un projet ou une intention : « Je vais prendre des vacances en '
          'juillet. »',
      'Quelque chose qui arrive bientôt : « La réunion va commencer. »',
      'À l’oral, c’est le futur le plus utilisé.',
    ],
    howToForm: [
      'Aller au présent + infinitif : je vais + envoyer.',
      'La négation entoure aller : « Je ne vais pas venir. »',
      'Les pronoms se placent avant l’infinitif : « Je vais vous '
          'appeler. » « Je vais me préparer. »',
    ],
    tables: [
      GrammarTable('aller + infinitif', [
        'je|vais partir',
        'tu|vas partir',
        '$_subjects|va partir',
        'nous|allons partir',
        'vous|allez partir',
        'ils / elles|vont partir',
      ]),
    ],
    examples: [
      'Je vais envoyer le rapport cet après-midi.|I am going to send the '
          'report this afternoon.',
      'Nous allons rencontrer le client demain.|We are going to meet the '
          'client tomorrow.',
      'Il ne va pas participer à la réunion.|He is not going to attend the '
          'meeting.',
      'Est-ce que vous allez prendre un congé ?|Are you going to take leave?',
      'Je vais vous rappeler dans dix minutes.|I am going to call you back '
          'in ten minutes.',
    ],
    pitfalls: [
      'Je vais à envoyer le courriel.|Je vais envoyer le courriel.|Pas de '
          'préposition entre aller et l’infinitif.',
      'Je vais envoie le rapport.|Je vais envoyer le rapport.|Le deuxième '
          'verbe reste à l’infinitif.',
      'Je vais pas venir.|Je ne vais pas venir.|Ne … pas entoure aller.',
    ],
    questions: [
      CourseQuestion(
        'Nous ___ commencer dans cinq minutes.',
        ['allons', 'allez', 'vont', 'va'],
        0,
        'Aller avec nous : allons.',
      ),
      CourseQuestion(
        'Choisissez la forme correcte.',
        [
          'Je vais à téléphoner.',
          'Je vais téléphone.',
          'Je vais téléphoner.',
          'Je vais téléphoné.',
        ],
        2,
        'Aller + infinitif, sans préposition.',
      ),
      CourseQuestion(
        'Choisissez la négation correcte.',
        [
          'Elle ne va pas venir.',
          'Elle va ne pas venir.',
          'Elle ne va venir pas.',
          'Elle va pas ne venir.',
        ],
        0,
        'Ne … pas entoure aller.',
      ),
      CourseQuestion(
        'Avec un pronom :',
        [
          'Je vais appeler vous.',
          'Je vous vais appeler.',
          'Je vais vous appeler.',
          'Je vais appeler à vous.',
        ],
        2,
        'Le pronom se place juste avant l’infinitif.',
      ),
    ],
    sayAloud: [
      'Dites trois choses que vous allez faire cette semaine.|Cette semaine, '
          'je vais finir mon rapport, je vais rencontrer mon équipe et je '
          'vais préparer une présentation.',
      'Dites ce que vous n’allez pas faire ce week-end.|Ce week-end, je ne '
          'vais pas travailler.',
      'Annoncez un changement à votre équipe.|Nous allons changer l’horaire '
          'des réunions à partir de lundi.',
    ],
    drillTopics: ['futur_proche'],
    referencePages: ['taf1|Futur proche'],
    conjugationVerb: 'aller',
    videoQuery: 'futur proche',
  ),
  GrammarLesson(
    id: 'g09-futur-simple',
    unit: 2,
    title: 'Le futur simple',
    summary: 'Parler d’un avenir plus lointain, promettre, prévoir.',
    englishKey:
        'The simple future ("will") is one word: the infinitive plus the '
        'endings of avoir. It sounds more formal and more distant than aller '
        '+ infinitive.',
    whenToUse: [
      'Une prévision ou un plan : « Le rapport sera prêt en mars. »',
      'Une promesse : « Je vous enverrai les documents demain. »',
      'Après quand, lorsque et dès que pour parler du futur : « Quand vous '
          'arriverez, appelez-moi. »',
    ],
    howToForm: [
      'Infinitif + -ai, -as, -a, -ons, -ez, -ont : je parlerai, nous '
          'finirons.',
      'Verbes en -re : on enlève le e final. Prendre → je prendrai.',
      'Radicaux irréguliers à mémoriser : être → ser-, avoir → aur-, '
          'aller → ir-, faire → fer-, pouvoir → pourr-, devoir → devr-, '
          'venir → viendr-, voir → verr-, envoyer → enverr-, savoir → saur-, '
          'vouloir → voudr-.',
    ],
    tables: [
      GrammarTable('parler', [
        'je|parlerai',
        'tu|parleras',
        '$_subjects|parlera',
        'nous|parlerons',
        'vous|parlerez',
        'ils / elles|parleront',
      ]),
      GrammarTable('Radicaux irréguliers (je)', [
        'être|serai',
        'avoir|aurai',
        'aller|irai',
        'faire|ferai',
        'pouvoir|pourrai',
        'devoir|devrai',
        'venir|viendrai',
        'envoyer|enverrai',
      ]),
    ],
    examples: [
      'La formation commencera en septembre.|The training will start in '
          'September.',
      'Je vous enverrai le compte rendu demain.|I will send you the minutes '
          'tomorrow.',
      'Nous aurons les résultats la semaine prochaine.|We will have the '
          'results next week.',
      'Quand vous serez prêt, nous commencerons.|When you are ready, we '
          'will start.',
      'Il faudra revoir le budget.|The budget will have to be reviewed.',
    ],
    pitfalls: [
      'Quand vous êtes prêt, nous commencerons.|Quand vous serez prêt, nous '
          'commencerons.|Après quand, pour le futur, le français met le '
          'futur.',
      'Je vous envoierai le document.|Je vous enverrai le document.|Envoyer '
          'est irrégulier : enverr-.',
      'Je serais là demain.|Je serai là demain.|Le futur se termine par '
          '-ai. Avec -ais, c’est le conditionnel.',
    ],
    questions: [
      CourseQuestion(
        'Demain, nous ___ les candidats.',
        ['rencontrions', 'rencontrerons', 'rencontrerions', 'rencontré'],
        1,
        'Futur avec nous : infinitif + -ons.',
      ),
      CourseQuestion(
        'Elle ___ en congé la semaine prochaine.',
        ['sera', 'serait', 'était', 'soit'],
        0,
        'Être au futur : elle sera.',
      ),
      CourseQuestion(
        'Quand il ___ , nous commencerons.',
        ['arrive', 'arrivera', 'arriverait', 'est arrivé'],
        1,
        'Après quand, pour le futur : le futur.',
      ),
      CourseQuestion(
        'Je vous ___ une réponse vendredi.',
        ['donnerai', 'donnerais', 'donnais', 'donné'],
        0,
        'Futur avec je : -ai.',
      ),
    ],
    sayAloud: [
      'Dites où vous serez dans un an sur le plan professionnel.|Dans un an, '
          'je serai plus à l’aise en français et j’aurai peut-être un '
          'nouveau poste.',
      'Promettez un document à un collègue.|Je vous enverrai le rapport '
          'avant la fin de la journée.',
      'Décrivez l’avenir de votre projet.|Le projet se terminera en mars et '
          'nous présenterons les résultats en avril.',
    ],
    drillTopics: ['futur_simple'],
    referencePages: [
      'taf2|Futur simple régulier',
      'taf3|Futur simple irrégulier',
    ],
    conjugationVerb: 'parler',
    videoQuery: 'futur simple',
  ),
];
