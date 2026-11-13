/// Units 3 to 5 of the grammar path: the past, the pronouns, and the forms
/// used to ask, advise and qualify.
library;

import '../course/course_catalog.dart' show CourseQuestion;
import 'grammar_course.dart';

const _subjects = 'il / elle / on';

const grammarLessonsB = <GrammarLesson>[
  GrammarLesson(
    id: 'g10-passe-compose-avoir',
    unit: 3,
    title: 'Le passé composé avec avoir',
    summary: 'Raconter ce que vous avez fait.',
    englishKey:
        'The main past tense for completed actions: avoir in the present + '
        'past participle. It covers both "I did" and "I have done".',
    whenToUse: [
      'Une action terminée dans le passé : « Hier, j’ai rencontré le '
          'directeur. »',
      'Une suite d’actions : « J’ai lu le dossier, j’ai appelé le client et '
          'j’ai écrit la réponse. »',
      'Avec hier, la semaine dernière, en 2022, il y a deux jours.',
    ],
    howToForm: [
      'Avoir au présent + participe passé : j’ai + travaillé.',
      'Participe : -er → -é (parlé), -ir → -i (fini), -re → -u (répondu).',
      'Beaucoup de verbes fréquents ont un participe irrégulier : voyez le '
          'tableau.',
      'La négation entoure avoir : « Je n’ai pas reçu le courriel. »',
    ],
    tables: [
      GrammarTable('travailler', [
        'j’|ai travaillé',
        'tu|as travaillé',
        '$_subjects|a travaillé',
        'nous|avons travaillé',
        'vous|avez travaillé',
        'ils / elles|ont travaillé',
      ]),
      GrammarTable('Participes irréguliers', [
        'faire|fait',
        'prendre|pris',
        'mettre|mis',
        'dire|dit',
        'écrire|écrit',
        'voir|vu',
        'lire|lu',
        'recevoir|reçu',
        'pouvoir|pu',
        'devoir|dû',
        'avoir|eu',
        'être|été',
      ]),
    ],
    examples: [
      'J’ai envoyé le rapport hier.|I sent the report yesterday.',
      'Nous avons fini la présentation.|We have finished the presentation.',
      'Elle a pris des notes pendant la réunion.|She took notes during the '
          'meeting.',
      'Je n’ai pas compris la question.|I did not understand the question.',
      'Avez-vous reçu mon message ?|Did you receive my message?',
    ],
    pitfalls: [
      'J’ai travaille hier.|J’ai travaillé hier.|Le participe des verbes en '
          '-er prend un accent : -é.',
      'J’ai prendu des notes.|J’ai pris des notes.|Prendre est irrégulier : '
          'pris.',
      'Je n’ai fini pas.|Je n’ai pas fini.|La négation entoure '
          'l’auxiliaire.',
    ],
    questions: [
      CourseQuestion(
        'Hier, nous ___ le contrat.',
        ['signons', 'avons signé', 'avons signer', 'sommes signé'],
        1,
        'Avoir au présent + participe en -é.',
      ),
      CourseQuestion(
        'Quel est le participe passé de « faire » ?',
        ['fais', 'faisé', 'fait', 'fé'],
        2,
        'Faire → fait.',
      ),
      CourseQuestion(
        'Elle ___ le dossier ce matin.',
        ['a lu', 'a lit', 'a lire', 'est lu'],
        0,
        'Lire → lu, avec avoir.',
      ),
      CourseQuestion(
        'Choisissez la forme négative correcte.',
        [
          'Je n’ai pas reçu le courriel.',
          'Je n’ai reçu pas le courriel.',
          'J’ai ne pas reçu le courriel.',
          'Je ne pas ai reçu le courriel.',
        ],
        0,
        'Ne … pas entoure l’auxiliaire avoir.',
      ),
    ],
    sayAloud: [
      'Racontez trois choses que vous avez faites hier au travail.|Hier, '
          'j’ai participé à une réunion, j’ai écrit deux courriels et j’ai '
          'préparé un rapport.',
      'Dites une chose que vous n’avez pas eu le temps de faire.|Je n’ai '
          'pas eu le temps de finir ma présentation.',
      'Racontez la dernière formation que vous avez suivie.|Le mois dernier, '
          'j’ai suivi une formation sur la gestion de projet. J’ai beaucoup '
          'appris.',
    ],
    drillTopics: ['passe_compose'],
    referencePages: ['tap2|Passé composé avec avoir'],
    conjugationVerb: 'faire',
    videoQuery: 'passé composé avec avoir',
  ),
  GrammarLesson(
    id: 'g11-passe-compose-etre',
    unit: 3,
    title: 'Le passé composé avec être',
    summary:
        'Raconter vos déplacements : je suis allé, je suis arrivé, je me '
        'suis levé.',
    englishKey:
        'About fifteen verbs of movement or change, and every pronominal '
        'verb, use être instead of avoir. The participle then agrees with '
        'the subject.',
    whenToUse: [
      'Verbes de déplacement ou de changement : aller, venir, arriver, '
          'partir, entrer, sortir, monter, descendre, rester, tomber, '
          'retourner, rentrer, naître, mourir, devenir.',
      'Tous les verbes pronominaux : « Je me suis levé tôt. »',
    ],
    howToForm: [
      'Être au présent + participe passé : je suis + allé.',
      'Le participe s’accorde avec le sujet : elle est allée, ils sont '
          'allés, elles sont allées.',
      'Verbe pronominal : je me suis inscrit, nous nous sommes réunis.',
      'Négation : « Je ne suis pas allé. » « Je ne me suis pas inscrit. »',
    ],
    tables: [
      GrammarTable('aller', [
        'je|suis allé(e)',
        'tu|es allé(e)',
        'il / on|est allé',
        'elle|est allée',
        'nous|sommes allé(e)s',
        'vous|êtes allé(e)(s)',
        'ils|sont allés',
        'elles|sont allées',
      ]),
      GrammarTable('Participes à connaître', [
        'venir|venu',
        'devenir|devenu',
        'partir|parti',
        'sortir|sorti',
        'rester|resté',
        'descendre|descendu',
        'naître|né',
      ]),
    ],
    examples: [
      'Je suis arrivé au bureau à huit heures.|I arrived at the office at '
          'eight.',
      'Elle est partie en congé vendredi.|She left on leave on Friday.',
      'Nous sommes restés tard hier soir.|We stayed late last night.',
      'Ils sont venus à la réunion.|They came to the meeting.',
      'Je me suis inscrit à la formation.|I registered for the training.',
    ],
    pitfalls: [
      'J’ai allé à Toronto.|Je suis allé à Toronto.|Aller se conjugue avec '
          'être.',
      'Elle est arrivé en retard.|Elle est arrivée en retard.|Avec être, le '
          'participe s’accorde avec le sujet.',
      'Je m’ai levé tôt.|Je me suis levé tôt.|Les verbes pronominaux '
          'prennent toujours être.',
    ],
    questions: [
      CourseQuestion(
        'Hier, elle ___ à Montréal.',
        ['a allé', 'est allé', 'est allée', 'a allée'],
        2,
        'Aller prend être, et le participe s’accorde : allée.',
      ),
      CourseQuestion(
        'Nous ___ à neuf heures.',
        ['avons arrivé', 'sommes arrivés', 'sommes arrivé', 'avons arrivés'],
        1,
        'Arriver prend être; avec nous, le participe est au pluriel.',
      ),
      CourseQuestion(
        'Je ___ à six heures ce matin.',
        ['m’ai levé', 'me suis levé', 'suis me levé', 'me levé'],
        1,
        'Un verbe pronominal prend être : je me suis levé.',
      ),
      CourseQuestion(
        'Quel verbe se conjugue avec avoir ?',
        ['partir', 'rester', 'travailler', 'venir'],
        2,
        'Travailler n’exprime ni déplacement ni changement d’état.',
      ),
    ],
    sayAloud: [
      'Racontez votre trajet de ce matin.|Ce matin, je suis parti de la '
          'maison à sept heures et je suis arrivé au bureau à sept heures '
          'quarante.',
      'Racontez votre dernier déplacement.|En août, je suis allé à Québec. '
          'Je suis resté trois jours et je suis rentré dimanche.',
      'Dites à quelle heure vous vous êtes levé et couché hier.|Hier, je me '
          'suis levé à six heures et je me suis couché vers onze heures.',
    ],
    drillTopics: ['passe_compose'],
    referencePages: [
      'tap3|Passé composé avec être',
      'tap4|Passé composé des verbes pronominaux',
    ],
    conjugationVerb: 'aller',
    videoQuery: 'passé composé avec être',
  ),
  GrammarLesson(
    id: 'g12-imparfait',
    unit: 3,
    title: 'L’imparfait',
    summary:
        'Décrire comment c’était avant et ce que vous faisiez régulièrement.',
    englishKey:
        'The imparfait is the "used to" and "was doing" past: background, '
        'habits and descriptions, not completed events.',
    whenToUse: [
      'Une habitude du passé : « Avant, je travaillais à Toronto. »',
      'Une description ou un état : « Il faisait froid. » « J’étais '
          'fatigué. »',
      'Une action en cours dans le passé : « Je préparais le rapport quand '
          'le téléphone a sonné. »',
    ],
    howToForm: [
      'Prenez la forme nous du présent, enlevez -ons et ajoutez : -ais, '
          '-ais, -ait, -ions, -iez, -aient.',
      'Nous finissons → je finissais. Nous faisons → je faisais. Nous '
          'prenons → je prenais.',
      'Une seule exception : être → j’étais.',
      'Les terminaisons -ais, -ait et -aient se prononcent de la même façon.',
    ],
    tables: [
      GrammarTable('travailler', [
        'je|travaillais',
        'tu|travaillais',
        '$_subjects|travaillait',
        'nous|travaillions',
        'vous|travailliez',
        'ils / elles|travaillaient',
      ]),
      GrammarTable('être · avoir', [
        'j’|étais · avais',
        'il / elle|était · avait',
        'nous|étions · avions',
        'ils / elles|étaient · avaient',
      ]),
    ],
    examples: [
      'Quand j’étais étudiant, j’habitais à Montréal.|When I was a student, '
          'I lived in Montreal.',
      'Avant, nous avions une réunion chaque matin.|We used to have a '
          'meeting every morning.',
      'Il y avait beaucoup de monde à la conférence.|There were a lot of '
          'people at the conference.',
      'Je ne savais pas que la réunion était annulée.|I did not know the '
          'meeting was cancelled.',
      'Elle travaillait sur le dossier quand je suis arrivé.|She was '
          'working on the file when I arrived.',
    ],
    pitfalls: [
      'Quand j’ai été jeune, j’ai habité à Lagos.|Quand j’étais jeune, '
          'j’habitais à Lagos.|Une période ou une situation du passé : '
          'imparfait.',
      'Avant, nous travaillons ensemble.|Avant, nous travaillions '
          'ensemble.|À l’imparfait, nous prend -ions.',
      'Avant, j’ai pris le train tous les jours.|Avant, je prenais le train '
          'tous les jours.|Une habitude se dit à l’imparfait.',
    ],
    questions: [
      CourseQuestion(
        'Avant, je ___ le train tous les jours.',
        ['ai pris', 'prenais', 'prendrai', 'prends'],
        1,
        'Une habitude du passé : imparfait.',
      ),
      CourseQuestion(
        'Quand elle ___ jeune, elle habitait à Québec.',
        ['a été', 'était', 'est', 'sera'],
        1,
        'Une période de la vie : imparfait de être.',
      ),
      CourseQuestion(
        'L’an dernier, nous ___ beaucoup de réunions.',
        ['avions', 'avons', 'aurions', 'ayons'],
        0,
        'Avoir à l’imparfait avec nous : avions.',
      ),
      CourseQuestion(
        'Quel est l’imparfait de « faire » avec je ?',
        ['je faisais', 'je fesais', 'je faisait', 'j’ai fait'],
        0,
        'Nous faisons → je faisais.',
      ),
    ],
    sayAloud: [
      'Décrivez votre ancien emploi.|Avant, je travaillais dans une banque. '
          'J’avais beaucoup de clients et les journées étaient longues.',
      'Dites ce que vous faisiez le week-end quand vous étiez étudiant.|'
          'Quand j’étais étudiant, je jouais au soccer et je voyais mes amis.',
      'Décrivez l’ambiance de votre dernier lundi.|Lundi, il pleuvait, le '
          'bureau était calme et tout le monde était fatigué.',
    ],
    drillTopics: ['imparfait'],
    referencePages: [
      'tap5|Imparfait : formation',
      'tap6|Imparfait : états et habitudes',
    ],
    conjugationVerb: 'faire',
    videoQuery: 'imparfait',
  ),
  GrammarLesson(
    id: 'g13-passe-compose-ou-imparfait',
    unit: 3,
    title: 'Passé composé ou imparfait ?',
    summary:
        'Raconter une histoire : le décor à l’imparfait, les événements au '
        'passé composé.',
    englishKey:
        'The imparfait sets the scene (what was going on). The passé composé '
        'moves the story forward (what happened).',
    whenToUse: [
      'Passé composé : un événement, une action terminée, un changement. '
          '« Le téléphone a sonné. »',
      'Imparfait : le contexte, une description, une habitude. « Il '
          'pleuvait. »',
      'Ensemble : « Je travaillais quand le directeur est entré. »',
    ],
    howToForm: [
      'Mots qui annoncent le passé composé : hier, soudain, tout à coup, '
          'une fois, à ce moment-là, en 2021.',
      'Mots qui annoncent l’imparfait : avant, d’habitude, souvent, tous '
          'les jours, pendant que, à cette époque.',
      'Posez-vous la question : est-ce que cela fait avancer l’histoire ? '
          'Si oui, passé composé.',
    ],
    tables: [
      GrammarTable('Choisir le temps', [
        'événement unique|passé composé',
        'durée précise et terminée|passé composé',
        'action qui interrompt|passé composé',
        'description, contexte|imparfait',
        'habitude|imparfait',
        'action interrompue|imparfait',
      ]),
    ],
    examples: [
      'Il pleuvait quand je suis sorti du bureau.|It was raining when I '
          'left the office.',
      'Avant, je prenais l’autobus; hier, j’ai pris le train.|I used to '
          'take the bus; yesterday I took the train.',
      'J’étais en réunion quand vous avez appelé.|I was in a meeting when '
          'you called.',
      'Nous avons travaillé pendant trois heures.|We worked for three hours.',
      'Comme le système ne fonctionnait pas, j’ai appelé le soutien '
          'technique.|Since the system was not working, I called technical '
          'support.',
    ],
    pitfalls: [
      'Hier, j’allais au bureau et je rencontrais le directeur.|Hier, je '
          'suis allé au bureau et j’ai rencontré le directeur.|Des '
          'événements précis d’hier : passé composé.',
      'Il a fait beau et j’ai été content.|Il faisait beau et j’étais '
          'content.|Le temps qu’il fait et les états : imparfait.',
      'Pendant que j’ai lu, il a téléphoné.|Pendant que je lisais, il a '
          'téléphoné.|L’action en cours est à l’imparfait.',
    ],
    questions: [
      CourseQuestion(
        'Je ___ mes courriels quand l’alarme ___ .',
        [
          'lisais … a sonné',
          'ai lu … sonnait',
          'lisais … sonnait',
          'ai lu … a sonné',
        ],
        0,
        'L’action en cours à l’imparfait, l’événement au passé composé.',
      ),
      CourseQuestion(
        'Quand j’habitais à Toronto, je ___ le métro tous les jours.',
        ['ai pris', 'prenais', 'prendrai', 'prends'],
        1,
        'Une habitude : imparfait.',
      ),
      CourseQuestion(
        'Hier, la réunion ___ deux heures.',
        ['durait', 'a duré', 'dure', 'durera'],
        1,
        'Une durée précise et terminée : passé composé.',
      ),
      CourseQuestion(
        'Il ___ très froid ce matin-là.',
        ['a fait', 'faisait', 'fera', 'fait'],
        1,
        'Une description du décor : imparfait.',
      ),
    ],
    sayAloud: [
      'Racontez un imprévu au travail : la situation, puis ce qui s’est '
          'passé.|Je préparais ma présentation quand mon ordinateur s’est '
          'arrêté. J’ai appelé le soutien technique et j’ai tout recommencé.',
      'Comparez avant et maintenant.|Avant, je travaillais au bureau tous '
          'les jours. L’an dernier, j’ai commencé le télétravail.',
      'Racontez votre première journée à votre poste.|J’étais nerveux. Mon '
          'gestionnaire m’a présenté l’équipe et j’ai reçu mon premier '
          'dossier.',
    ],
    drillTopics: ['passe_compose', 'imparfait'],
    referencePages: ['tap8|Raconter : passé composé et imparfait'],
    videoQuery: 'passé composé ou imparfait',
  ),
  GrammarLesson(
    id: 'g14-pronoms-objets',
    unit: 4,
    title: 'Les pronoms le, la, les, lui, leur',
    summary: 'Éviter de répéter un nom.',
    englishKey:
        'Object pronouns replace a noun and go before the verb. Le, la, les '
        'replace a direct object; lui and leur replace à + a person.',
    whenToUse: [
      'Le, la, l’, les remplacent un complément direct : « Je lis le '
          'rapport. → Je le lis. »',
      'Lui et leur remplacent à + une personne : « Je parle à Marie. → Je '
          'lui parle. »',
      'Me, te, nous, vous servent dans les deux cas : « Il m’appelle. » '
          '« Il me parle. »',
    ],
    howToForm: [
      'Le pronom se place avant le verbe conjugué : « Je l’envoie. »',
      'Avec deux verbes, avant l’infinitif : « Je vais l’envoyer. » « Je '
          'peux lui parler. »',
      'Au passé composé, avant l’auxiliaire : « Je l’ai envoyé. » « Je lui '
          'ai parlé. »',
      'Verbes suivis de à + personne : parler à, téléphoner à, répondre à, '
          'écrire à, demander à, dire à.',
    ],
    tables: [
      GrammarTable('Les pronoms', [
        'direct|me · te · le / la · nous · vous · les',
        'indirect|me · te · lui · nous · vous · leur',
      ]),
      GrammarTable('La place du pronom', [
        'verbe simple|Je le lis.',
        'négation|Je ne le lis pas.',
        'deux verbes|Je vais le lire.',
        'passé composé|Je l’ai lu.',
      ]),
    ],
    examples: [
      'Le rapport ? Je l’envoie tout de suite.|The report? I am sending it '
          'right away.',
      'Je lui ai parlé ce matin.|I spoke to him this morning.',
      'Nous leur répondrons demain.|We will answer them tomorrow.',
      'Pouvez-vous me rappeler plus tard ?|Can you call me back later?',
      'Je ne les ai pas encore lus.|I have not read them yet.',
    ],
    pitfalls: [
      'Je téléphone le.|Je lui téléphone.|Téléphoner à quelqu’un : lui, et '
          'avant le verbe.',
      'Je vais envoyer le.|Je vais l’envoyer.|Le pronom se place avant '
          'l’infinitif.',
      'Je leurs ai écrit.|Je leur ai écrit.|Le pronom leur ne prend jamais '
          'de s.',
    ],
    questions: [
      CourseQuestion(
        'Le dossier ? Je ___ ai déjà lu.',
        ['le', 'l’', 'lui', 'la'],
        1,
        'Complément direct, et l’ devant une voyelle.',
      ),
      CourseQuestion(
        'Je parle à la directrice. → Je ___ parle.',
        ['la', 'le', 'lui', 'leur'],
        2,
        'Parler à une personne : lui.',
      ),
      CourseQuestion(
        'Nous écrivons aux clients. → Nous ___ écrivons.',
        ['les', 'leur', 'leurs', 'lui'],
        1,
        'Écrire à plusieurs personnes : leur, sans s.',
      ),
      CourseQuestion(
        'Choisissez la place correcte du pronom.',
        [
          'Je vais le envoyer.',
          'Je le vais envoyer.',
          'Je vais l’envoyer.',
          'Je vais envoyer le.',
        ],
        2,
        'Avant l’infinitif, et l’ devant une voyelle.',
      ),
    ],
    sayAloud: [
      'Répondez sans répéter le nom : « Avez-vous lu le rapport ? »|Oui, je '
          'l’ai lu hier.',
      'Répondez sans répéter le nom : « Avez-vous parlé à votre '
          'gestionnaire ? »|Oui, je lui ai parlé ce matin.',
      'Dites ce que vous allez envoyer à vos collègues, puis reformulez '
          'avec un pronom.|Je vais envoyer l’ordre du jour à mes collègues. '
          'Je vais leur envoyer l’ordre du jour.',
    ],
    drillTopics: ['pronoms_cod_coi'],
    referencePages: [
      'pro5|Pronoms compléments directs',
      'pro8|Pronoms compléments indirects',
    ],
    videoQuery: 'pronoms COD COI le la les lui leur',
  ),
  GrammarLesson(
    id: 'g15-y-en',
    unit: 4,
    title: 'Les pronoms y et en',
    summary: 'Remplacer un lieu, une quantité ou un groupe introduit par de.',
    englishKey:
        'Y replaces à + a place or a thing ("there", "about it"). En '
        'replaces de + something, or a quantity ("some", "of it").',
    whenToUse: [
      'Y remplace un lieu, ou à + une chose : « Je vais au bureau. → J’y '
          'vais. » « Je pense au projet. → J’y pense. »',
      'En remplace de + une chose, ou une quantité : « J’ai des '
          'questions. → J’en ai. » « Je parle du budget. → J’en parle. »',
      'On garde la quantité : « J’en ai trois. » « J’en ai beaucoup. »',
    ],
    howToForm: [
      'Y et en se placent avant le verbe, comme les autres pronoms.',
      'Avec deux verbes : « Je vais y aller. » « Je voudrais en parler. »',
      'Négation : « Je n’y vais pas. » « Je n’en ai pas. »',
      'Pour une personne, on n’emploie pas y : « Je pense à elle. »',
    ],
    tables: [
      GrammarTable('Ce qu’ils remplacent', [
        'à + lieu|J’y travaille.',
        'à + chose|J’y pense.',
        'de + chose|J’en parle.',
        'du / des + nom|J’en ai.',
        'quantité|J’en ai deux.',
      ]),
    ],
    examples: [
      'Vous allez à la réunion ? — Oui, j’y vais.|Are you going to the '
          'meeting? — Yes, I am.',
      'Avez-vous des questions ? — Oui, j’en ai une.|Do you have questions? '
          '— Yes, I have one.',
      'Je m’en occupe.|I will take care of it.',
      'Nous y réfléchissons depuis lundi.|We have been thinking about it '
          'since Monday.',
      'Il n’y en a plus.|There is none left.',
    ],
    pitfalls: [
      'J’ai trois.|J’en ai trois.|Avec une quantité seule, il faut en.',
      'J’y vais au bureau.|J’y vais.|Y remplace le lieu : on ne dit pas '
          'les deux.',
      'Je en ai besoin.|J’en ai besoin.|Devant une voyelle : j’en, j’y.',
    ],
    questions: [
      CourseQuestion(
        'Vous allez à Toronto ? — Oui, j’___ vais mardi.',
        ['en', 'y', 'le', 'lui'],
        1,
        'Un lieu introduit par à : y.',
      ),
      CourseQuestion(
        'Voulez-vous du café ? — Oui, j’___ veux bien.',
        ['y', 'le', 'en', 'la'],
        2,
        'Du + nom : en.',
      ),
      CourseQuestion(
        'Combien de dossiers avez-vous ? — J’___ ai cinq.',
        ['les', 'y', 'en', 'leur'],
        2,
        'Avec une quantité : en.',
      ),
      CourseQuestion(
        'Vous pensez au projet ? — Oui, j’___ pense souvent.',
        ['en', 'y', 'lui', 'le'],
        1,
        'Penser à une chose : y.',
      ),
    ],
    sayAloud: [
      'Répondez : « Allez-vous souvent au bureau ? »|Oui, j’y vais trois '
          'fois par semaine.',
      'Répondez : « Avez-vous beaucoup de réunions ? »|Oui, j’en ai '
          'beaucoup, surtout le lundi.',
      'Proposez de vous occuper d’un problème.|Ne vous inquiétez pas, je '
          'm’en occupe cet après-midi.',
    ],
    drillTopics: ['pronoms_y_en'],
    referencePages: ['pro6|Le pronom y', 'pro7|Le pronom en'],
    videoQuery: 'pronoms y et en',
  ),
  GrammarLesson(
    id: 'g16-pronoms-relatifs',
    unit: 4,
    title: 'Qui, que, où, dont',
    summary: 'Relier deux phrases pour parler de façon plus fluide.',
    englishKey:
        'Relative pronouns join two sentences. Qui is a subject, que is an '
        'object, où is a place or a time, dont replaces de + a noun.',
    whenToUse: [
      'Qui est le sujet du verbe qui suit : « la collègue qui travaille '
          'avec moi ».',
      'Que est le complément direct : « le rapport que j’ai écrit ».',
      'Où indique un lieu ou un moment : « le bureau où je travaille », '
          '« le jour où je suis arrivé ».',
      'Dont remplace de + un nom : « le projet dont je parle ».',
    ],
    howToForm: [
      'Après qui, il y a un verbe. Après que, il y a un sujet.',
      'Que devient qu’ devant une voyelle; qui ne change jamais.',
      'Dont s’emploie avec parler de, avoir besoin de, s’occuper de, être '
          'responsable de, se souvenir de.',
    ],
    tables: [
      GrammarTable('Lequel choisir', [
        'qui|sujet : la personne qui appelle',
        'que / qu’|objet : le courriel que j’envoie',
        'où|lieu, moment : la salle où nous sommes',
        'dont|de + nom : le dossier dont j’ai besoin',
      ]),
    ],
    examples: [
      'C’est la directrice qui a approuvé le budget.|It is the director who '
          'approved the budget.',
      'Voici le document que vous avez demandé.|Here is the document you '
          'asked for.',
      'Je travaille dans un service où tout le monde est bilingue.|I work '
          'in a unit where everyone is bilingual.',
      'C’est un outil dont nous avons besoin.|It is a tool we need.',
      'Le projet dont je suis responsable se termine en mars.|The project I '
          'am responsible for ends in March.',
    ],
    pitfalls: [
      'Le collègue que travaille avec moi.|Le collègue qui travaille avec '
          'moi.|Devant un verbe : qui.',
      'Le rapport qui j’ai écrit.|Le rapport que j’ai écrit.|Devant un '
          'sujet : que.',
      'Le dossier que j’ai besoin.|Le dossier dont j’ai besoin.|Avoir '
          'besoin de : dont.',
    ],
    questions: [
      CourseQuestion(
        'La personne ___ vous cherchez est en réunion.',
        ['qui', 'que', 'où', 'dont'],
        1,
        'Devant un sujet (vous) : que.',
      ),
      CourseQuestion(
        'J’ai un collègue ___ parle quatre langues.',
        ['qui', 'que', 'dont', 'où'],
        0,
        'Devant un verbe : qui.',
      ),
      CourseQuestion(
        'C’est le projet ___ je vous ai parlé.',
        ['que', 'qui', 'dont', 'où'],
        2,
        'Parler de quelque chose : dont.',
      ),
      CourseQuestion(
        'Ottawa est la ville ___ je travaille.',
        ['que', 'qui', 'dont', 'où'],
        3,
        'Un lieu : où.',
      ),
    ],
    sayAloud: [
      'Décrivez un collègue avec « qui ».|J’ai une collègue qui connaît '
          'très bien le système et qui aide tout le monde.',
      'Décrivez un document avec « que ».|Le rapport que je prépare cette '
          'semaine porte sur le budget.',
      'Employez « où », puis « dont ».|Je travaille dans un édifice où il y '
          'a un bon café. La formation dont j’ai besoin commence en mai.',
    ],
    drillTopics: ['pronoms_relatifs_simples'],
    referencePages: ['pror1|Qui et que', 'pror3|Dont et où'],
    videoQuery: 'pronoms relatifs qui que où dont',
  ),
  GrammarLesson(
    id: 'g17-imperatif',
    unit: 5,
    title: 'L’impératif',
    summary: 'Donner une consigne ou un conseil clairement.',
    englishKey:
        'The imperative gives instructions. It is the present tense without '
        'its subject, in three forms: tu, nous, vous.',
    whenToUse: [
      'Une consigne : « Remplissez ce formulaire. »',
      'Un conseil ou une invitation : « Prenez votre temps. » '
          '« Commençons. »',
      'Au travail, on l’adoucit souvent : « Veuillez… », « s’il vous '
          'plaît ».',
    ],
    howToForm: [
      'Le présent sans le sujet : vous envoyez → « Envoyez ! »',
      'Verbes en -er avec tu : pas de -s. Tu parles → « Parle ! »',
      'Irréguliers : être → sois, soyons, soyez; avoir → aie, ayons, ayez; '
          'savoir → sachez; vouloir → veuillez.',
      'Le pronom suit le verbe à l’affirmatif (« Envoyez-le. » '
          '« Appelez-moi. ») et le précède au négatif (« Ne l’envoyez '
          'pas. »).',
    ],
    tables: [
      GrammarTable('Les trois formes', [
        'tu|Envoie le courriel.',
        'nous|Envoyons le courriel.',
        'vous|Envoyez le courriel.',
      ]),
      GrammarTable('Avec un pronom', [
        'affirmatif|Envoyez-le. · Dites-moi.',
        'négatif|Ne l’envoyez pas. · Ne me dites pas.',
      ]),
    ],
    examples: [
      'Veuillez signer ici, s’il vous plaît.|Please sign here.',
      'Envoyez-moi le document avant midi.|Send me the document before noon.',
      'N’oubliez pas la réunion de demain.|Do not forget tomorrow’s meeting.',
      'Soyez à l’heure.|Be on time.',
      'Commençons par le premier point.|Let us start with the first item.',
    ],
    pitfalls: [
      'Vous envoyez-moi le fichier.|Envoyez-moi le fichier.|Pas de sujet à '
          'l’impératif.',
      'Envoyez me le fichier.|Envoyez-moi le fichier.|Après le verbe, me '
          'devient moi, avec un trait d’union.',
      'N’envoyez-le pas.|Ne l’envoyez pas.|Au négatif, le pronom revient '
          'avant le verbe.',
    ],
    questions: [
      CourseQuestion(
        '___ ce formulaire, s’il vous plaît.',
        ['Vous remplissez', 'Remplissez', 'Remplir', 'Remplissiez'],
        1,
        'Le présent avec vous, sans le sujet.',
      ),
      CourseQuestion(
        '___ à l’heure demain. (être, vous)',
        ['Êtes', 'Soyez', 'Serez', 'Étiez'],
        1,
        'Être est irrégulier à l’impératif : soyez.',
      ),
      CourseQuestion(
        'Avec un pronom :',
        [
          'Appelez-moi demain.',
          'Appelez me demain.',
          'Me appelez demain.',
          'Moi appelez demain.',
        ],
        0,
        'Après le verbe : moi, avec un trait d’union.',
      ),
      CourseQuestion(
        'Choisissez la forme négative correcte.',
        [
          'Ne oubliez pas.',
          'N’oubliez pas.',
          'Oubliez ne pas.',
          'Oubliez pas ne.',
        ],
        1,
        'Ne … pas entoure le verbe, et ne devient n’ devant une voyelle.',
      ),
    ],
    sayAloud: [
      'Donnez trois consignes à un nouvel employé.|Présentez-vous à '
          'l’accueil, remplissez le formulaire et demandez votre carte '
          'd’accès.',
      'Invitez votre équipe à commencer la réunion.|Bonjour à tous. '
          'Commençons par l’ordre du jour.',
      'Demandez poliment un document.|Envoyez-moi le rapport quand vous '
          'aurez un moment, s’il vous plaît.',
    ],
    drillTopics: ['imperatif'],
    referencePages: ['tai1|L’impératif'],
    videoQuery: 'impératif',
  ),
  GrammarLesson(
    id: 'g18-conditionnel',
    unit: 5,
    title: 'Le conditionnel de politesse',
    summary:
        'Demander poliment et exprimer un souhait : je voudrais, '
        'pourriez-vous, il faudrait.',
    englishKey:
        'The conditional ("would", "could", "should") softens a request or '
        'a suggestion. It is the future stem + the imparfait endings.',
    whenToUse: [
      'Une demande polie : « Pourriez-vous m’aider ? » « Je voudrais un '
          'renseignement. »',
      'Un conseil ou une suggestion : « Vous devriez en parler à votre '
          'gestionnaire. » « Il faudrait vérifier. »',
      'Un souhait : « J’aimerais suivre cette formation. »',
    ],
    howToForm: [
      'Radical du futur + -ais, -ais, -ait, -ions, -iez, -aient.',
      'Je parlerai (futur) → je parlerais (conditionnel).',
      'Mêmes radicaux irréguliers qu’au futur : ser-, aur-, ir-, fer-, '
          'pourr-, devr-, voudr-, faudr-.',
    ],
    tables: [
      GrammarTable('Les formes les plus utiles', [
        'je|voudrais · pourrais · devrais · aimerais',
        'vous|voudriez · pourriez · devriez · aimeriez',
        'il|faudrait · serait · aurait',
      ]),
      GrammarTable('parler', [
        'je|parlerais',
        'tu|parlerais',
        '$_subjects|parlerait',
        'nous|parlerions',
        'vous|parleriez',
        'ils / elles|parleraient',
      ]),
    ],
    examples: [
      'Pourriez-vous répéter, s’il vous plaît ?|Could you repeat, please?',
      'Je voudrais prendre rendez-vous.|I would like to make an appointment.',
      'Vous devriez vérifier les chiffres.|You should check the figures.',
      'Il faudrait prévenir l’équipe.|The team should be told.',
      'J’aimerais avoir votre avis.|I would like to have your opinion.',
    ],
    pitfalls: [
      'Je veux un renseignement.|Je voudrais un renseignement.|Je veux est '
          'trop direct pour une demande.',
      'Vous devez vérifier les chiffres.|Vous devriez vérifier les '
          'chiffres.|Pour un conseil, le conditionnel est plus poli que '
          'l’obligation.',
      'Je voudrai un café.|Je voudrais un café.|-ai, c’est le futur; -ais, '
          'le conditionnel.',
    ],
    questions: [
      CourseQuestion(
        '___-vous m’envoyer le fichier ?',
        ['Pourrez', 'Pourriez', 'Pouviez', 'Puissiez'],
        1,
        'Demande polie : conditionnel de pouvoir.',
      ),
      CourseQuestion(
        'Je ___ parler à la responsable.',
        ['voudrais', 'voulais', 'voudrai', 'veuille'],
        0,
        'Souhait poli : je voudrais.',
      ),
      CourseQuestion(
        'Vous ___ en parler à votre gestionnaire. (conseil)',
        ['devez', 'devriez', 'deviez', 'devrez'],
        1,
        'Un conseil : vous devriez.',
      ),
      CourseQuestion(
        'Il ___ commencer plus tôt.',
        ['faudrait', 'fallait', 'faudra que', 'faut que'],
        0,
        'Une suggestion : il faudrait + infinitif.',
      ),
    ],
    sayAloud: [
      'Demandez poliment un renseignement au téléphone.|Bonjour, je '
          'voudrais un renseignement, s’il vous plaît. Pourriez-vous me '
          'dire vos heures d’ouverture ?',
      'Donnez un conseil à un collègue débordé.|Vous devriez en parler à '
          'votre gestionnaire. Il faudrait revoir les priorités.',
      'Exprimez un souhait pour votre carrière.|J’aimerais obtenir un poste '
          'bilingue et je voudrais suivre plus de formations.',
    ],
    drillTopics: ['conditionnel_politesse'],
    referencePages: ['tac1|Le conditionnel'],
    conjugationVerb: 'pouvoir',
    videoQuery: 'conditionnel présent politesse',
  ),
  GrammarLesson(
    id: 'g19-hypotheses-si',
    unit: 5,
    title: 'Les hypothèses avec si',
    summary: 'Dire ce qui se passera si… et ce qui se passerait si…',
    englishKey:
        'Two patterns cover most needs: si + present → future (a real '
        'possibility); si + imparfait → conditional (an imagined situation). '
        'Never put the future or the conditional right after si.',
    whenToUse: [
      'Une possibilité réelle : si + présent, puis futur. « Si j’ai le '
          'temps, je vous appellerai. »',
      'Une situation imaginée : si + imparfait, puis conditionnel. « Si '
          'j’avais le temps, je vous appellerais. »',
      'C’est la structure des questions hypothétiques de l’évaluation '
          'orale : « Que feriez-vous si… ? »',
    ],
    howToForm: [
      'Après si : jamais de futur, jamais de conditionnel.',
      'Si devient s’ devant il et ils : s’il pleut, s’ils viennent.',
      'L’ordre est libre : « Je vous appellerai si j’ai le temps. »',
    ],
    tables: [
      GrammarTable('Deux structures', [
        'possible|si + présent → futur',
        'exemple|Si vous envoyez le formulaire, nous traiterons la demande.',
        'imaginé|si + imparfait → conditionnel',
        'exemple|Si j’étais gestionnaire, je changerais l’horaire.',
      ]),
    ],
    examples: [
      'Si vous avez des questions, appelez-moi.|If you have questions, call '
          'me.',
      'S’il pleut demain, nous resterons au bureau.|If it rains tomorrow, '
          'we will stay at the office.',
      'Si j’avais plus de temps, je suivrais ce cours.|If I had more time, '
          'I would take this course.',
      'Que feriez-vous si un collègue refusait de collaborer ?|What would '
          'you do if a colleague refused to cooperate?',
      'Si j’étais à votre place, j’en parlerais au directeur.|If I were '
          'you, I would talk to the director about it.',
    ],
    pitfalls: [
      'Si j’aurais le temps, je viendrais.|Si j’avais le temps, je '
          'viendrais.|Jamais de conditionnel après si : imparfait.',
      'Si vous viendrez, nous commencerons.|Si vous venez, nous '
          'commencerons.|Jamais de futur après si : présent.',
      'Si il arrive en retard…|S’il arrive en retard…|Si + il = s’il.',
    ],
    questions: [
      CourseQuestion(
        'Si j’___ le temps, je vous aiderais.',
        ['ai', 'aurais', 'avais', 'aurai'],
        2,
        'Le conditionnel dans la suite appelle l’imparfait après si.',
      ),
      CourseQuestion(
        'Si vous envoyez le dossier aujourd’hui, nous le ___ demain.',
        ['traitions', 'traiterons', 'traiterions', 'avons traité'],
        1,
        'Si + présent, puis futur.',
      ),
      CourseQuestion(
        'Que ___-vous si votre projet était annulé ?',
        ['ferez', 'faites', 'feriez', 'faisiez'],
        2,
        'Si + imparfait, puis conditionnel : feriez.',
      ),
      CourseQuestion(
        'Choisissez la phrase correcte.',
        [
          'Si j’aurais su, je viendrais.',
          'Si je serais libre, je viendrais.',
          'Si j’étais libre, je viendrais.',
          'Si je suis libre, je viendrais.',
        ],
        2,
        'Si + imparfait, puis conditionnel.',
      ),
    ],
    sayAloud: [
      'Dites ce que vous ferez si vous finissez tôt aujourd’hui.|Si je '
          'finis tôt aujourd’hui, j’irai me promener.',
      'Répondez : « Que feriez-vous si vous étiez gestionnaire ? »|Si '
          'j’étais gestionnaire, j’organiserais moins de réunions et je '
          'donnerais plus d’autonomie à l’équipe.',
      'Répondez : « Que feriez-vous si un collègue arrivait toujours en '
          'retard ? »|Je lui parlerais en privé et je lui demanderais s’il '
          'a besoin d’aide.',
    ],
    referencePages: ['tac3|Les phrases avec si'],
    videoQuery: 'hypothèse si imparfait conditionnel',
  ),
  GrammarLesson(
    id: 'g20-subjonctif',
    unit: 5,
    title: 'Le subjonctif présent',
    summary: 'Exprimer une nécessité ou un souhait : il faut que, je veux que.',
    englishKey:
        'The subjunctive follows que after necessity, wishes and emotions. '
        'Start with il faut que and je veux que: they cover most everyday '
        'uses.',
    whenToUse: [
      'Une nécessité : « Il faut que vous signiez ce document. »',
      'Une volonté ou un souhait : « Je veux que tout soit prêt. » '
          '« J’aimerais que vous veniez. »',
      'Une émotion ou un doute : « Je suis content que vous soyez là. » '
          '« Je ne pense pas que ce soit possible. »',
    ],
    howToForm: [
      'Prenez la forme ils du présent, enlevez -ent et ajoutez : -e, -es, '
          '-e, -ions, -iez, -ent.',
      'Ils finissent → que je finisse. Ils prennent → que je prenne.',
      'Les verbes les plus fréquents sont irréguliers : voyez le tableau.',
      'Même sujet dans les deux parties : on emploie l’infinitif. « Je '
          'veux partir. »',
    ],
    tables: [
      GrammarTable('parler', [
        'que je|parle',
        'que tu|parles',
        'qu’il / elle / on|parle',
        'que nous|parlions',
        'que vous|parliez',
        'qu’ils / elles|parlent',
      ]),
      GrammarTable('Irréguliers (je · nous)', [
        'être|sois · soyons',
        'avoir|aie · ayons',
        'aller|aille · allions',
        'faire|fasse · fassions',
        'pouvoir|puisse · puissions',
        'savoir|sache · sachions',
      ]),
    ],
    examples: [
      'Il faut que je finisse ce rapport aujourd’hui.|I have to finish this '
          'report today.',
      'Il faut que vous soyez là à neuf heures.|You have to be there at '
          'nine.',
      'Je voudrais que vous m’envoyiez le fichier.|I would like you to send '
          'me the file.',
      'Je suis content que le projet avance.|I am glad the project is '
          'moving forward.',
      'Il est important que nous ayons une réponse.|It is important that '
          'we have an answer.',
    ],
    pitfalls: [
      'Il faut que vous êtes à l’heure.|Il faut que vous soyez à '
          'l’heure.|Après il faut que : subjonctif.',
      'Je veux que vous venez.|Je veux que vous veniez.|Vouloir que est '
          'suivi du subjonctif.',
      'J’espère que vous puissiez venir.|J’espère que vous pourrez '
          'venir.|Espérer que est suivi de l’indicatif.',
    ],
    questions: [
      CourseQuestion(
        'Il faut que nous ___ une décision.',
        ['prenons', 'prenions', 'prendrons', 'prendre'],
        1,
        'Subjonctif avec nous : -ions.',
      ),
      CourseQuestion(
        'Je voudrais que vous ___ présent.',
        ['êtes', 'serez', 'soyez', 'étiez'],
        2,
        'Être au subjonctif : que vous soyez.',
      ),
      CourseQuestion(
        'Il faut que j’___ à la banque.',
        ['aille', 'vais', 'irai', 'allais'],
        0,
        'Aller au subjonctif : que j’aille.',
      ),
      CourseQuestion(
        'Même sujet : « Je veux ___ tôt. »',
        ['que je parte', 'partir', 'que je pars', 'partant'],
        1,
        'Avec le même sujet, on emploie l’infinitif.',
      ),
    ],
    sayAloud: [
      'Dites deux choses qu’il faut que vous fassiez cette semaine.|Il faut '
          'que je finisse mon rapport et il faut que j’appelle un client.',
      'Dites ce que vous voulez que votre équipe fasse.|Je voudrais que '
          'l’équipe soit prête lundi et que tout le monde lise le document.',
      'Exprimez votre satisfaction.|Je suis content que le projet avance '
          'bien.',
    ],
    drillTopics: ['subjonctif_present', 'verbes_volonte'],
    referencePages: [
      'tas1|Subjonctif régulier',
      'tas2|Subjonctif irrégulier',
      'tas3a|Emploi : l’obligation',
    ],
    videoQuery: 'subjonctif présent il faut que',
  ),
];
