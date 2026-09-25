/// Original teaching material, not official or recalled SLE test questions.
const courseId = 'b-to-c-v1';
const courseCriteriaUrl =
    'https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/oral-language-assessment-sle/about-the-test.html';

class CourseModule {
  const CourseModule(this.number, this.title, this.goal);
  final int number;
  final String title, goal;
}

class CourseQuestion {
  const CourseQuestion(
    this.prompt,
    this.options,
    this.correct,
    this.explanation,
  );
  final String prompt, explanation;
  final List<String> options;
  final int correct;
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.module,
    required this.title,
    required this.objective,
    required this.teaching,
    required this.simpleExample,
    required this.developedExample,
    required this.phrases,
    required this.exercise,
    required this.modelAnswer,
    required this.questions,
    required this.speakingTask,
    required this.criteria,
  });
  final String id,
      title,
      objective,
      simpleExample,
      developedExample,
      exercise,
      modelAnswer,
      speakingTask;
  final int module;
  final List<String> teaching, phrases, criteria;
  final List<CourseQuestion> questions;

  /// Include the listening/summary source so the partner can evaluate meaning
  /// without inventing the referenced discussion. Never include personal notes.
  String get partnerPrompt => [
    'Objectif de cette classe : $objective',
    if (module == 6) ...[
      'Support pédagogique (ce n’est pas une réponse de l’apprenant) : $developedExample',
      'Exercice associé : $exercise',
    ],
    'Votre tâche : $speakingTask',
  ].join('\n\n');
}

const courseModules = [
  CourseModule(
    1,
    'Consolider un discours clair',
    'Décrire avec précision et raconter un événement sans perdre le fil.',
  ),
  CourseModule(
    2,
    'Relier les idées',
    'Construire des phrases reliées, précises et faciles à suivre.',
  ),
  CourseModule(
    3,
    'Défendre et comparer',
    'Soutenir une opinion, peser les options et expliquer un compromis.',
  ),
  CourseModule(
    4,
    'Nuancer et recommander',
    'Reconnaître une objection et formuler une recommandation adaptée.',
  ),
  CourseModule(
    5,
    'Imaginer et analyser',
    'Explorer des hypothèses présentes et des conséquences passées.',
  ),
  CourseModule(
    6,
    'Comprendre et synthétiser',
    'Écouter des positions différentes et en restituer fidèlement le sens.',
  ),
  CourseModule(
    7,
    'Aborder le complexe',
    'Expliquer une notion abstraite et gérer une discussion délicate.',
  ),
  CourseModule(
    8,
    'Gagner en aisance',
    'Reformuler, répondre aux relances et transférer les acquis à une situation nouvelle.',
  ),
];

const bToCLessons = <CourseLesson>[
  CourseLesson(
    id: '01-detail',
    module: 1,
    title: 'Développer une réponse',
    objective:
        'Passer d’une réponse courte à une explication organisée, sans réciter un texte.',
    teaching: [
      'Une réponse développée répond d’abord à la question. Ajoutez ensuite une raison, un exemple concret et une conséquence. Cette structure est un soutien, pas une formule obligatoire.',
      'Précisez les acteurs, la contrainte et votre action : « un dossier urgent » devient plus clair si vous expliquez pour qui il était urgent et ce qui empêchait son traitement.',
      'La précision ne signifie pas parler longtemps. Gardez les détails qui aident votre interlocuteur à comprendre votre décision; éliminez les répétitions.',
      'Préparez trois mots-clés, puis parlez sans lire. Un contenu familier permet de concentrer votre attention sur les liens entre les idées.',
    ],
    simpleExample:
        'J’organise le travail de l’équipe. C’est parfois difficile.',
    developedExample:
        'Je coordonne les demandes de notre équipe. La difficulté principale est de traiter les urgences sans retarder les autres dossiers. Par exemple, lundi, j’ai réparti une demande complexe entre deux collègues afin de respecter le délai. Nous avons ainsi maintenu le service habituel.',
    phrases: [
      'La difficulté principale est…',
      'Concrètement…',
      'Cela nous permet de…',
    ],
    exercise:
        'Développez « J’ai changé notre façon de travailler » avec une raison et une conséquence.',
    modelAnswer:
        'J’ai changé notre façon de travailler parce que nous recevions des demandes en double. Nous utilisons maintenant un registre commun, ce qui réduit les vérifications inutiles.',
    questions: [
      CourseQuestion(
        'Quel détail soutient le mieux une explication ?',
        [
          'Un exemple lié à la décision',
          'Tous les détails du dossier',
          'Une longue liste de mots difficiles',
        ],
        0,
        'Un exemple pertinent rend le raisonnement concret sans détourner la réponse.',
      ),
      CourseQuestion(
        'Comment utiliser un modèle de réponse ?',
        [
          'Le réciter exactement',
          'En reprendre l’organisation avec son propre exemple',
          'Allonger chaque phrase',
        ],
        1,
        'L’organisation aide; votre réponse doit rester adaptée à la question.',
      ),
    ],
    speakingTask:
        'Présentez une difficulté réelle ou fictive de votre travail. Expliquez votre action, donnez un exemple et précisez le résultat. Puis répondez : qu’auriez-vous pu faire autrement ?',
    criteria: [
      'J’ai répondu directement à la question.',
      'J’ai donné un exemple pertinent.',
      'J’ai expliqué une conséquence plutôt que répété mon idée.',
    ],
  ),
  CourseLesson(
    id: '02-narration',
    module: 1,
    title: 'Raconter avec les bons repères',
    objective:
        'Distinguer le contexte, les événements et ce qui s’était produit auparavant.',
    teaching: [
      'L’imparfait installe le contexte ou une habitude : « l’équipe travaillait à distance ». Le passé composé présente un événement : « nous avons reçu une demande urgente ». Les deux temps peuvent décrire des actions; c’est leur rôle dans le récit qui compte.',
      'Le plus-que-parfait indique une action antérieure à un autre moment passé : « nous avions déjà envoyé le rapport quand la consigne a changé ». Il se forme avec avoir ou être à l’imparfait et le participe passé.',
      'Utilisez quelques repères : au départ, ce jour-là, entre-temps, finalement. Évitez de commencer chaque phrase par « et puis ».',
      'Terminez le récit par ce que vous avez appris. Vous passez ainsi de la simple succession d’événements à l’explication.',
    ],
    simpleExample:
        'Il y a eu un changement. Nous avons eu un problème. Nous avons parlé.',
    developedExample:
        'Nous préparions une consultation lorsque le délai a été raccourci. Comme nous avions déjà recueilli une partie des commentaires, nous avons pu présenter un bilan provisoire. Cette expérience m’a appris à prévoir une solution de rechange.',
    phrases: [
      'Nous étions en train de… lorsque…',
      'Nous avions déjà…',
      'Avec le recul…',
    ],
    exercise:
        'Reliez ces faits : l’équipe préparait un atelier; une panne est survenue; une salle avait été réservée auparavant.',
    modelAnswer:
        'L’équipe préparait un atelier lorsqu’une panne est survenue. Heureusement, nous avions réservé une autre salle, ce qui nous a permis de poursuivre.',
    questions: [
      CourseQuestion(
        'Complétez : Nous ___ le rapport quand le téléphone a sonné.',
        ['rédigions', 'rédigerions', 'rédigerons'],
        0,
        'L’imparfait présente l’activité en cours au moment de l’événement.',
      ),
      CourseQuestion(
        'Quel énoncé place clairement une action avant une autre action passée ?',
        [
          'Nous enverrons le rapport.',
          'Nous envoyons le rapport.',
          'Nous avions envoyé le rapport avant la réunion.',
        ],
        2,
        'Le plus-que-parfait marque ici l’antériorité par rapport à la réunion.',
      ),
    ],
    speakingTask:
        'Racontez un imprévu professionnel. Situez le contexte, un événement déclencheur, votre réaction et la leçon retenue. Puis expliquez pourquoi votre réaction était appropriée.',
    criteria: [
      'Le contexte et les événements sont distingués.',
      'L’ordre des événements est compréhensible.',
      'J’ai expliqué ce que j’ai appris.',
    ],
  ),
  CourseLesson(
    id: '03-precision',
    module: 2,
    title: 'Éviter les répétitions sans perdre le sens',
    objective:
        'Employer les pronoms et les relatives pour garder un référent clair.',
    teaching: [
      'Le, la et les remplacent un complément direct : « je consulte le rapport → je le consulte ». Lui et leur remplacent souvent à + une personne : « j’explique la règle aux collègues → je leur explique la règle ». Vérifiez d’abord la construction du verbe.',
      'Y peut reprendre un lieu ou à + une chose : « je réfléchis à cette option → j’y réfléchis ». En reprend notamment de + une chose : « nous discutons de ce risque → nous en discutons ». Ces substitutions ne conviennent pas indistinctement à tous les compléments.',
      'Dans une relative, qui est sujet, que est complément direct et dont reprend souvent un complément introduit par de : « le dossier dont je parle ». Avec une autre préposition, une forme comme « sur lequel » peut être nécessaire.',
      'Un pronom n’améliore pas la phrase si l’on ne sait plus à quoi il renvoie. Répétez le nom quand plusieurs référents sont possibles.',
    ],
    simpleExample:
        'J’ai reçu un rapport. Le rapport décrit un risque. Nous parlons de ce risque.',
    developedExample:
        'J’ai reçu un rapport qui décrit le risque dont nous parlons. Je l’ai transmis à la gestionnaire et je lui ai proposé d’en discuter demain.',
    phrases: [
      'Le point dont je parle…',
      'La solution à laquelle je pense…',
      'J’y vois un avantage…',
    ],
    exercise:
        'Réduisez les répétitions : « Je parle du projet. Je présente le projet à mes collègues. »',
    modelAnswer:
        'Je parle du projet que je présente à mes collègues. Je leur en explique les objectifs.',
    questions: [
      CourseQuestion(
        'Le dossier ___ je parle est urgent.',
        ['que', 'dont', 'qui'],
        1,
        'On parle de quelque chose : dont reprend ce complément en de.',
      ),
      CourseQuestion(
        'Je transmets la note à mes collègues. Je ___ transmets la note.',
        ['leur', 'les', 'en'],
        0,
        'Transmettre quelque chose à quelqu’un : leur reprend à mes collègues.',
      ),
    ],
    speakingTask:
        'Expliquez un projet à un nouveau collègue. Présentez les personnes, un document et un risque. Employez des pronoms quand le référent est clair, puis reformulez un passage ambigu.',
    criteria: [
      'Mes pronoms renvoient à un élément identifiable.',
      'J’ai relié deux idées avec une relative.',
      'Je peux préciser un nom si mon interlocuteur hésite.',
    ],
  ),
  CourseLesson(
    id: '04-coherence',
    module: 2,
    title: 'Rendre le raisonnement visible',
    objective: 'Choisir un lien logique qui correspond réellement au sens.',
    teaching: [
      'Parce que introduit une cause; donc ou par conséquent annonce un résultat. Pour ou afin de introduit un objectif, qui n’est pas forcément déjà atteint.',
      'Cependant et en revanche signalent une opposition ou un contraste. De plus ajoute un élément allant dans le même sens. Ne les utilisez pas seulement pour varier le vocabulaire.',
      'Une phrase longue n’est pas automatiquement plus claire. Présentez une idée principale, puis reliez-la à la suivante par le bon connecteur.',
      'Pour résumer votre raisonnement, demandez-vous : est-ce une cause, une conséquence, un but ou une limite ? Cette question est plus utile que mémoriser une liste isolée.',
    ],
    simpleExample:
        'Le service est lent. Nous avons changé le formulaire. Il reste des problèmes.',
    developedExample:
        'Nous avons simplifié le formulaire afin de réduire les délais. Le traitement est donc plus rapide. Cependant, certains dossiers complexes nécessitent encore une vérification manuelle.',
    phrases: ['Puisque…', 'Par conséquent…', 'Cela dit…'],
    exercise:
        'Reliez « Les demandes augmentent » et « Nous devons revoir les priorités », puis ajoutez une limite.',
    modelAnswer:
        'Les demandes augmentent; nous devons donc revoir les priorités. Cependant, les dossiers urgents doivent continuer à être traités rapidement.',
    questions: [
      CourseQuestion(
        '« Afin de réduire les délais » exprime…',
        ['un objectif', 'un résultat garanti', 'une opposition'],
        0,
        'Afin de introduit un but, pas la preuve que ce but est atteint.',
      ),
      CourseQuestion(
        'Le coût a diminué. ___, le délai s’est allongé.',
        ['De plus', 'En revanche', 'Parce que'],
        1,
        'En revanche met en contraste un avantage et un inconvénient.',
      ),
    ],
    speakingTask:
        'Expliquez pourquoi un processus devrait changer, le résultat attendu et une limite possible. Reprenez ensuite votre explication en trois phrases courtes.',
    criteria: [
      'Mes connecteurs correspondent au sens.',
      'J’ai distingué un objectif d’un résultat observé.',
      'Mon raisonnement reste clair en version courte.',
    ],
  ),
  CourseLesson(
    id: '05-opinion',
    module: 3,
    title: 'Soutenir une opinion',
    objective:
        'Défendre une position avec des raisons, un exemple et une limite.',
    teaching: [
      'Une opinion soutenue ne se limite pas à « je suis pour ». Expliquez le critère qui compte pour vous : qualité, accessibilité, équité, délai ou coût.',
      'Un exemple illustre une raison; il ne prouve pas à lui seul une règle générale. Distinguez votre expérience d’une conclusion qui s’appliquerait partout.',
      'Répondez à une objection honnêtement. Vous pouvez maintenir votre position tout en indiquant les circonstances qui vous feraient changer d’avis.',
      'Préparez plusieurs façons de développer une idée, et non un discours appris. Une relance doit pouvoir modifier votre réponse.',
    ],
    simpleExample: 'Je préfère le travail hybride parce que c’est mieux.',
    developedExample:
        'Je privilégie une organisation hybride, surtout pour les tâches qui exigent de la concentration. Dans mon équipe, certaines analyses avancent mieux sans interruptions. Cela dit, je garderais des rencontres en personne pour les décisions qui demandent une discussion approfondie.',
    phrases: [
      'À mon avis, l’enjeu principal est…',
      'Cette position repose sur…',
      'Je changerais d’avis si…',
    ],
    exercise:
        'Défendez une formation commune sans utiliser « c’est mieux » comme seule justification.',
    modelAnswer:
        'Une formation commune me paraît utile parce qu’elle donne à tous les mêmes repères. Elle ne remplace toutefois pas l’accompagnement adapté aux tâches de chacun.',
    questions: [
      CourseQuestion(
        'Quelle phrase soutient une opinion ?',
        [
          'C’est évident.',
          'Je suis pour, parce que cette option réduit les étapes inutiles.',
          'Tout le monde le sait.',
        ],
        1,
        'La raison précise rend la position défendable.',
      ),
      CourseQuestion(
        'Que faire d’une objection pertinente ?',
        [
          'L’ignorer',
          'Répéter sa première phrase',
          'L’examiner et préciser la portée de sa position',
        ],
        2,
        'Reconnaître une limite rend le raisonnement plus nuancé.',
      ),
    ],
    speakingTask:
        'Votre organisation envisage une formation obligatoire pour tous. Défendez votre position avec deux raisons et un exemple. Puis répondez à un collègue qui craint une perte de temps.',
    criteria: [
      'Ma position est identifiable.',
      'J’ai développé des raisons distinctes.',
      'J’ai répondu à une objection sans simplement répéter.',
    ],
  ),
  CourseLesson(
    id: '06-options',
    module: 3,
    title: 'Comparer et choisir un compromis',
    objective: 'Comparer deux options à l’aide de critères communs.',
    teaching: [
      'Comparez les mêmes dimensions pour chaque option. Une option peut être moins coûteuse mais plus lente; votre choix dépend alors de la priorité du dossier.',
      'Plus… que, moins… que et aussi… que servent à comparer. Meilleur qualifie généralement un nom; mieux modifie souvent un verbe : « un meilleur outil », « il fonctionne mieux ».',
      'Annoncez le compromis : quel avantage acceptez-vous de réduire pour protéger une autre priorité ? Ne présentez pas toute solution comme parfaite.',
      'Ajoutez une condition de réévaluation. Vous montrez ainsi que votre recommandation tient compte d’un contexte changeant.',
    ],
    simpleExample: 'L’option A est rapide. L’option B est bonne. Je choisis A.',
    developedExample:
        'L’option A serait plus rapide à mettre en place que l’option B, mais elle offrirait moins de souplesse. Comme le délai est notre priorité immédiate, je retiendrais A pour une période d’essai, à condition de revoir les résultats après un mois.',
    phrases: [
      'Si l’on privilégie…',
      'Le principal compromis concerne…',
      'À court terme…; à plus long terme…',
    ],
    exercise:
        'Comparez un outil simple et peu coûteux à un outil complet qui exige une formation.',
    modelAnswer:
        'L’outil simple coûterait moins cher et serait utilisable immédiatement. L’outil complet répondrait mieux aux besoins futurs, mais demanderait une formation. Je commencerais par préciser la durée prévue du projet.',
    questions: [
      CourseQuestion(
        'Ce nouvel outil fonctionne ___ que l’ancien.',
        ['meilleur', 'mieux', 'le meilleur'],
        1,
        'Mieux modifie le verbe fonctionner.',
      ),
      CourseQuestion(
        'Quelle comparaison permet une décision justifiée ?',
        [
          'Comparer les deux options selon le coût et le délai',
          'Citer seulement les qualités de son option préférée',
          'Changer de critère pour chaque option sans le dire',
        ],
        0,
        'Des critères communs rendent les avantages et limites comparables.',
      ),
    ],
    speakingTask:
        'Choisissez entre recruter temporairement et réorganiser les tâches d’une équipe surchargée. Comparez coût, délai et qualité, puis expliquez le compromis que vous accepteriez.',
    criteria: [
      'J’ai comparé les mêmes critères.',
      'J’ai nommé un inconvénient de mon choix.',
      'J’ai précisé quand réévaluer la décision.',
    ],
  ),
  CourseLesson(
    id: '07-concession',
    module: 4,
    title: 'Reconnaître une limite sans abandonner son idée',
    objective: 'Employer la concession et les structures utiles au subjonctif.',
    teaching: [
      'La concession admet un fait qui pourrait aller contre votre conclusion : « bien que le délai soit court, le projet reste réalisable ». Elle ne signifie pas que les deux idées s’annulent.',
      'Bien que et pour que appellent le subjonctif. Même si s’emploie normalement avec l’indicatif : « même si le délai est court ». Évitez « malgré que » dans cette pratique professionnelle; utilisez malgré + nom ou bien que + proposition.',
      'Le subjonctif présent se construit souvent sur le radical de ils au présent, avec -e, -es, -e, -ions, -iez, -ent. Des formes fréquentes sont irrégulières : soit, ait, fasse, puisse.',
      'La valeur de la phrase compte davantage que la présence d’une forme complexe. Choisissez une construction que vous maîtrisez plutôt qu’une formule compliquée sans rapport avec votre idée.',
    ],
    simpleExample: 'Le délai est court. Le projet est possible.',
    developedExample:
        'Bien que le délai soit court, le projet reste réalisable si nous réduisons sa portée. Je reconnais toutefois que cette solution laisserait certains besoins sans réponse.',
    phrases: ['Bien que…', 'Même si…', 'Je reconnais que…; toutefois…'],
    exercise:
        'Reformulez « L’outil est utile, mais il ne répond pas à tous les besoins » avec bien que.',
    modelAnswer:
        'Bien que l’outil soit utile, il ne répond pas à tous les besoins.',
    questions: [
      CourseQuestion(
        'Bien que cette option ___ coûteuse, elle reste pertinente.',
        ['est', 'soit', 'sera'],
        1,
        'Bien que est suivi du subjonctif.',
      ),
      CourseQuestion(
        'Même si le délai ___ court, nous pouvons agir.',
        ['est', 'soit', 'serait'],
        0,
        'Même si introduit ici un fait et se construit avec l’indicatif.',
      ),
    ],
    speakingTask:
        'Défendez une solution imparfaite. Reconnaissez deux limites, expliquez pourquoi vous la maintenez et proposez une mesure pour réduire un risque.',
    criteria: [
      'J’ai reconnu une vraie limite.',
      'Ma concession reste cohérente avec ma conclusion.',
      'J’ai utilisé une formulation que je peux expliquer.',
    ],
  ),
  CourseLesson(
    id: '08-advice',
    module: 4,
    title: 'Recommander sans imposer',
    objective:
        'Adapter le degré de certitude et distinguer souhait, nécessité et constat.',
    teaching: [
      'Le conditionnel peut atténuer une recommandation : « nous pourrions », « il serait préférable de ». Cette prudence n’interdit pas une position claire.',
      'Il faut que, je souhaite que et je recommande que appellent le subjonctif : « je recommande que nous fassions un essai ». Avec le même acteur, une construction à l’infinitif est souvent plus simple : « nous souhaitons essayer ».',
      'Distinguez ce que vous savez, supposez et recommandez. « Les résultats montrent… » n’a pas la même force que « il semble que… » ou « je proposerais… ».',
      'Une recommandation utile comporte une action, une raison et une façon de vérifier les résultats. Évitez les demandes vagues comme « il faut améliorer les choses ».',
    ],
    simpleExample: 'Il faut changer le processus. C’est nécessaire.',
    developedExample:
        'Je recommanderais que nous fassions un essai auprès d’une petite équipe. Cela nous permettrait de vérifier les effets du nouveau processus avant de le généraliser. Il faudrait aussi recueillir les commentaires des utilisateurs.',
    phrases: [
      'Je proposerais de…',
      'Il serait préférable que…',
      'Pour vérifier cette hypothèse…',
    ],
    exercise:
        'Transformez « Vous devez remplacer l’outil » en recommandation justifiée et prudente.',
    modelAnswer:
        'Je vous suggérerais d’évaluer un autre outil, car plusieurs fonctions semblent manquer. Un essai limité permettrait de vérifier si le remplacement répond réellement au besoin.',
    questions: [
      CourseQuestion(
        'Je recommande que l’équipe ___ un essai.',
        ['fait', 'fera', 'fasse'],
        2,
        'La recommandation introduite par que appelle ici le subjonctif.',
      ),
      CourseQuestion(
        'Quelle phrase distingue clairement une proposition d’un constat ?',
        [
          'Je proposerais de tester cette option.',
          'Il est certain que mon idée est parfaite.',
          'Personne ne peut être en désaccord.',
        ],
        0,
        'Le conditionnel présente une proposition sans la transformer en vérité établie.',
      ),
    ],
    speakingTask:
        'Votre gestionnaire vous demande comment améliorer l’accueil des nouveaux collègues. Proposez une action, justifiez-la et expliquez comment vous en mesureriez l’utilité.',
    criteria: [
      'J’ai formulé une action concrète.',
      'J’ai distingué constat et recommandation.',
      'J’ai proposé un moyen de vérifier les effets.',
    ],
  ),
  CourseLesson(
    id: '09-hypothesis',
    module: 5,
    title: 'Explorer une hypothèse',
    objective:
        'Relier une condition présente ou future à ses conséquences possibles.',
    teaching: [
      'Pour une possibilité ouverte : si + présent, puis présent, futur ou impératif selon le sens. Exemple : « si le budget augmente, nous recruterons ».',
      'Pour une situation imaginée ou moins probable : si + imparfait, puis conditionnel présent. Exemple : « si le budget augmentait, nous recruterions ». Dans cette condition, on ne dit pas « si le budget augmenterait ».',
      'Le conditionnel présent utilise généralement le radical du futur et les terminaisons de l’imparfait : nous ferions, vous pourriez, ils auraient.',
      'Développez plus d’une conséquence et signalez une incertitude. Une hypothèse sert à raisonner, pas seulement à placer deux temps de verbe.',
    ],
    simpleExample: 'Avec plus de temps, ce serait mieux.',
    developedExample:
        'Si nous disposions de plus de temps, nous consulterions davantage les utilisateurs. Nous pourrions ainsi repérer des difficultés avant le lancement, même si cela ne garantirait pas l’absence de problèmes.',
    phrases: [
      'Si nous disposions de…',
      'Cela aurait pour effet de…',
      'Tout dépendrait de…',
    ],
    exercise:
        'Corrigez puis développez : « Si j’aurais plus de ressources, je changerais le service. »',
    modelAnswer:
        'Si j’avais plus de ressources, je renforcerais l’accompagnement des nouveaux utilisateurs. Cela pourrait réduire les erreurs, à condition de bien cibler les besoins.',
    questions: [
      CourseQuestion(
        'Si nous ___ plus de temps, nous consulterions les équipes.',
        ['aurions', 'avions', 'aurons'],
        1,
        'Si + imparfait correspond à cette hypothèse suivie du conditionnel.',
      ),
      CourseQuestion(
        'Si la demande augmente demain, nous ___ les priorités.',
        ['reverrons', 'aurions revu', 'avions revu'],
        0,
        'Si + présent peut être suivi du futur pour une conséquence possible à venir.',
      ),
    ],
    speakingTask:
        'Imaginez que votre équipe perde un quart de ses ressources. Quelles priorités conserveriez-vous, quelles conséquences prévoiriez-vous et quelle incertitude resterait à vérifier ?',
    criteria: [
      'Ma condition et mes temps verbaux sont cohérents.',
      'J’ai développé au moins deux conséquences.',
      'J’ai reconnu une incertitude.',
    ],
  ),
  CourseLesson(
    id: '10-hindsight',
    module: 5,
    title: 'Analyser ce qui aurait pu se passer',
    objective:
        'Exprimer une hypothèse passée et en tirer une leçon sans blâmer.',
    teaching: [
      'Pour imaginer un passé différent : si + plus-que-parfait, puis conditionnel passé. Exemple : « si nous avions consulté l’équipe, nous aurions repéré le risque ».',
      'Le conditionnel passé se forme avec avoir ou être au conditionnel et le participe passé : aurait compris, serait arrivé. Les règles habituelles d’accord du participe restent applicables.',
      'Une hypothèse n’est pas une certitude : « nous aurions peut-être évité ce retard » est parfois plus honnête que « tout aurait été parfait ».',
      'Séparez l’analyse du blâme. Décrivez l’information qui manquait et ce que vous feriez différemment lors du prochain projet.',
    ],
    simpleExample: 'Nous avons commencé tard. Le projet a été retardé.',
    developedExample:
        'Si nous avions clarifié les rôles dès le départ, nous aurions probablement évité certaines vérifications en double. Nous ne pouvions toutefois pas prévoir la panne. Pour le prochain projet, je proposerais un point de coordination plus tôt.',
    phrases: [
      'Si nous avions su…',
      'Nous aurions pu…',
      'La prochaine fois, je…',
    ],
    exercise:
        'Transformez « Nous n’avons pas testé l’outil; nous n’avons pas repéré le problème » en hypothèse passée.',
    modelAnswer:
        'Si nous avions testé l’outil, nous aurions peut-être repéré le problème avant le lancement.',
    questions: [
      CourseQuestion(
        'Si nous avions anticipé le risque, nous ___ une autre option.',
        ['choisirons', 'choisissons', 'aurions choisi'],
        2,
        'Le conditionnel passé exprime la conséquence imaginée dans le passé.',
      ),
      CourseQuestion(
        'Pourquoi ajouter « probablement » dans une analyse rétrospective ?',
        [
          'Pour présenter une incertitude réelle',
          'Pour éviter toute explication',
          'Pour prouver que le résultat était certain',
        ],
        0,
        'Une hypothèse rétrospective ne permet pas toujours d’affirmer le résultat avec certitude.',
      ),
    ],
    speakingTask:
        'Racontez une décision qui n’a pas donné le résultat attendu. Analysez une autre possibilité dans le passé, distinguez ce qui était prévisible et proposez une leçon pour l’avenir.',
    criteria: [
      'J’ai utilisé une hypothèse passée cohérente.',
      'J’ai distingué probabilité et certitude.',
      'J’ai tiré une leçon constructive.',
    ],
  ),
  CourseLesson(
    id: '11-summary',
    module: 6,
    title: 'Résumer plusieurs points de vue',
    objective:
        'Restituer l’essentiel d’une discussion sans y ajouter son opinion.',
    teaching: [
      'Un résumé distingue le sujet, les positions, les points d’accord et ce qui reste à décider. Il n’est pas une liste chronologique de toutes les phrases entendues.',
      'Attribuez les positions : « selon Nadia… », « Marc souligne que… ». Ne transformez pas la préférence d’une personne en décision collective.',
      'Le discours indirect permet de rapporter une idée : « elle explique que le délai est trop court ». Quand le verbe introducteur est au passé, les temps peuvent changer selon le repère temporel et la validité actuelle du fait.',
      'Séparez le résumé de votre commentaire par une transition explicite. Votre interlocuteur doit savoir quand vous cessez de rapporter et commencez à recommander.',
    ],
    simpleExample:
        'Nadia veut lancer le service. Marc parle de formation. On a discuté.',
    developedExample:
        'Nadia privilégie un lancement rapide, tandis que Marc souhaite former les agents auparavant. Tous deux veulent éviter une interruption du service. La question qui reste à régler concerne donc l’ordre des étapes, et non l’objectif du projet.',
    phrases: [
      'Les deux personnes s’accordent sur…',
      'Le désaccord porte sur…',
      'Aucune décision n’a encore été prise concernant…',
    ],
    exercise:
        'Résumez : « Nadia : lançons lundi. Marc : attendons la formation. Nadia : une petite équipe pourrait commencer lundi. Marc : d’accord pour en discuter. »',
    modelAnswer:
        'Nadia propose un démarrage limité lundi; Marc souhaite tenir compte de la formation. Ils envisagent d’en discuter, mais ils n’ont pas encore confirmé le lancement.',
    questions: [
      CourseQuestion(
        '« D’accord pour en discuter » signifie-t-il que le lancement est approuvé ?',
        [
          'Oui, définitivement',
          'Non, seule la discussion est acceptée',
          'Oui, pour toute l’organisation',
        ],
        1,
        'Accepter une discussion n’équivaut pas à approuver la proposition.',
      ),
      CourseQuestion(
        'Quel élément doit rester distinct du résumé ?',
        [
          'Le sujet discuté',
          'Les positions des participants',
          'Votre propre recommandation',
        ],
        2,
        'Votre recommandation peut suivre le résumé, mais elle doit être identifiée comme telle.',
      ),
    ],
    speakingTask:
        'Résumez la discussion entre Nadia et Marc avec vos propres mots. Distinguez accord, désaccord et décision en suspens. Ajoutez ensuite votre recommandation en l’annonçant clairement.',
    criteria: [
      'J’ai attribué les positions correctement.',
      'Je n’ai pas inventé de décision.',
      'J’ai séparé résumé et recommandation.',
    ],
  ),
  CourseLesson(
    id: '12-listening',
    module: 6,
    title: 'Écouter une réserve et reformuler',
    objective:
        'Repérer une condition ou une réserve sans la transformer en refus.',
    teaching: [
      'Dans une discussion complexe, les réserves sont souvent plus importantes que le premier « oui ». Repérez à condition que, sous réserve de, pourvu que, toutefois et sauf si.',
      'Écoutez d’abord pour le sens global, puis vérifiez les détails. Notez quelques mots-clés plutôt que de tenter d’écrire chaque phrase.',
      'Une inférence doit rester liée aux indices du message. Si plusieurs interprétations sont possibles, posez une question de clarification.',
      'Écoutez l’exemple avec le bouton audio sans regarder le texte. Reformulez ensuite la condition, puis vérifiez. Cette voix synthétique est un entraînement guidé, pas un enregistrement de l’examen.',
    ],
    simpleExample: 'On peut lancer le projet, mais il y a une condition.',
    developedExample:
        'Je ne m’oppose pas à un lancement ce mois-ci, à condition que les équipes disposent d’un soutien suffisant. En revanche, si les demandes dépassent notre capacité, il faudra limiter temporairement le nombre de participants. Ce n’est donc pas la date seule qui déterminera notre décision.',
    phrases: [
      'Si je comprends bien, votre réserve concerne…',
      'Est-ce que cela signifie que… ?',
      'Vous seriez donc favorable à… à condition que…',
    ],
    exercise:
        'Après l’écoute de l’exemple, exprimez la position en une phrase, puis posez une question utile.',
    modelAnswer:
        'La personne accepte un lancement ce mois-ci si le soutien est suffisant. Quel niveau de soutien faudrait-il prévoir pour démarrer dans de bonnes conditions ?',
    questions: [
      CourseQuestion(
        'Dans l’exemple, la personne refuse-t-elle tout lancement ce mois-ci ?',
        [
          'Oui',
          'Non, elle pose une condition de soutien',
          'Elle accepte sans réserve',
        ],
        1,
        'La réserve concerne la capacité de soutien, pas un refus absolu de la date.',
      ),
      CourseQuestion(
        'Quelle question vérifie le mieux une incertitude ?',
        [
          'Pourquoi êtes-vous contre tout changement ?',
          'Quel soutien considérez-vous comme suffisant ?',
          'Pourquoi avez-vous déjà approuvé le projet ?',
        ],
        1,
        'Cette question clarifie le critère sans attribuer une position que la personne n’a pas exprimée.',
      ),
    ],
    speakingTask:
        'Reformulez la réserve de l’exemple puis simulez une réponse professionnelle : proposez une mesure de soutien, vérifiez votre compréhension et expliquez un risque qui demeure.',
    criteria: [
      'J’ai identifié la condition principale.',
      'Ma reformulation ne transforme pas la réserve en refus.',
      'J’ai posé une question qui clarifie vraiment.',
    ],
  ),
  CourseLesson(
    id: '13-abstract',
    module: 7,
    title: 'Expliquer une notion abstraite',
    objective:
        'Relier un principe à une situation concrète et en montrer les tensions.',
    teaching: [
      'Pour expliquer une notion comme l’équité, commencez par ce qu’elle signifie dans le contexte. Donnez ensuite un exemple observable : que ferait-on différemment si on appliquait ce principe ?',
      'Distinguez des notions proches. Traiter tout le monde de façon identique n’est pas toujours la même chose que répondre équitablement à des besoins différents.',
      'Les principes peuvent entrer en tension : rapidité et consultation, transparence et confidentialité. Montrez comment vous chercheriez un équilibre au lieu d’affirmer qu’un principe règle tout.',
      'Le vocabulaire abstrait est utile s’il précise la pensée. Expliquez simplement un terme technique lorsqu’il n’est pas nécessaire à votre interlocuteur.',
    ],
    simpleExample: 'L’équité est importante. Il faut être juste.',
    developedExample:
        'Dans l’accès à une formation, l’équité consiste à offrir des possibilités réelles de participation. Un horaire identique pour tous peut sembler égal, mais exclure des employés en région. Je proposerais donc plusieurs plages horaires, tout en vérifiant que le contenu reste comparable.',
    phrases: [
      'Dans ce contexte, j’entends par…',
      'Ce principe se traduit concrètement par…',
      'La tension se situe entre…',
    ],
    exercise:
        'Expliquez « la transparence » avec un exemple et une limite liée à la confidentialité.',
    modelAnswer:
        'La transparence suppose d’expliquer les critères d’une décision. On peut publier ces critères sans divulguer les renseignements personnels des personnes concernées.',
    questions: [
      CourseQuestion(
        'Quelle explication rend une notion abstraite plus claire ?',
        [
          'Une définition liée à un exemple concret',
          'La répétition du même nom',
          'Des termes techniques non expliqués',
        ],
        0,
        'L’exemple montre comment le principe influence une action.',
      ),
      CourseQuestion(
        'Transparence et confidentialité peuvent-elles être discutées ensemble ?',
        [
          'Non, il faut ignorer l’une des deux',
          'Oui, en distinguant critères publics et renseignements protégés',
          'Oui, en divulguant tout',
        ],
        1,
        'On peut expliquer une décision tout en protégeant certains renseignements.',
      ),
    ],
    speakingTask:
        'Expliquez ce que signifie un service public accessible. Donnez un exemple, examinez une tension avec les ressources disponibles et proposez une façon d’évaluer les progrès.',
    criteria: [
      'J’ai défini la notion dans son contexte.',
      'J’ai illustré le principe concrètement.',
      'J’ai expliqué une tension ou une limite.',
    ],
  ),
  CourseLesson(
    id: '14-disagreement',
    module: 7,
    title: 'Gérer un désaccord délicat',
    objective: 'Exprimer une divergence avec précision et respect.',
    teaching: [
      'Commencez par un objectif commun, puis nommez le point précis de divergence. Vous pouvez reconnaître une intention sans approuver la solution proposée.',
      'Décrivez un comportement observable plutôt que juger une personne. « Le dossier a été transmis après le délai » est plus précis que « vous êtes toujours négligent ».',
      'Pour proposer une autre voie, combinez une réserve et une option : « je crains que…; pourrions-nous… ? ». Après je crains que, le subjonctif est attendu : « je crains que les équipes ne soient pas prêtes » exprime la crainte d’un manque de préparation.',
      'Vérifiez l’accord sur la prochaine étape. Un ton poli ne suffit pas si personne ne sait ce qui est décidé. Utilisez des situations fictives, sans révéler de renseignements confidentiels.',
    ],
    simpleExample: 'Votre idée ne fonctionne pas. Il faut faire autrement.',
    developedExample:
        'Je partage votre objectif de simplifier le service. Ma réserve concerne surtout le délai de transition : je crains que certaines équipes ne soient pas prêtes. Pourrions-nous prévoir un déploiement progressif et vérifier la situation après deux semaines ?',
    phrases: [
      'Je partage votre objectif, mais…',
      'Ma réserve porte sur…',
      'Sur quelle prochaine étape pouvons-nous nous entendre ?',
    ],
    exercise:
        'Reformulez « Vous ne respectez jamais les délais » en observation et demande constructive.',
    modelAnswer:
        'Les deux derniers dossiers sont arrivés après la date prévue. Pourrions-nous revoir les étapes afin d’identifier ce qui retarde leur transmission ?',
    questions: [
      CourseQuestion(
        'Quelle formulation décrit un fait plutôt qu’un jugement global ?',
        [
          'Vous êtes toujours désorganisé.',
          'Le dossier est arrivé deux jours après la date prévue.',
          'Vous ne faites jamais attention.',
        ],
        1,
        'L’observation est précise et vérifiable; elle facilite une discussion sur la solution.',
      ),
      CourseQuestion(
        'Après avoir exprimé une réserve, quelle étape est utile ?',
        [
          'Proposer une option et vérifier l’accord',
          'Changer de sujet immédiatement',
          'Répéter le reproche',
        ],
        0,
        'Une option et une prochaine étape permettent de faire avancer l’échange.',
      ),
    ],
    speakingTask:
        'Un collègue veut appliquer immédiatement un changement que vous jugez risqué. Reconnaissez son objectif, exprimez une réserve précise et négociez une prochaine étape.',
    criteria: [
      'J’ai nommé le désaccord sans attaquer la personne.',
      'J’ai justifié ma réserve.',
      'J’ai proposé et clarifié une prochaine étape.',
    ],
  ),
  CourseLesson(
    id: '15-fluency',
    module: 8,
    title: 'Continuer même quand un mot manque',
    objective: 'Reformuler et clarifier sans recommencer toute la réponse.',
    teaching: [
      'L’aisance ne signifie pas parler sans aucune pause. L’objectif est de maintenir un message compréhensible; une courte pause pour organiser une idée peut être utile.',
      'Quand un mot manque, décrivez sa fonction, donnez un exemple ou utilisez un terme plus général. Évitez de chercher trop longtemps une seule formulation parfaite.',
      'Corrigez une erreur qui change le sens, puis poursuivez. Recommencer chaque phrase peut rompre le fil davantage qu’une petite imperfection.',
      'Faites trois essais de la même idée : deux minutes, puis quatre-vingt-dix secondes, puis une minute. Ne cherchez pas à accélérer; sélectionnez mieux vos idées. Ces durées sont des exercices, pas des exigences de l’ÉLS.',
    ],
    simpleExample: 'Je… je ne connais pas le mot… je recommence tout.',
    developedExample:
        'Nous avons utilisé un outil pour suivre les demandes — autrement dit, un registre partagé qui indique qui s’occupe de chaque dossier. Ce qui compte ici, c’est que chacun puisse voir l’état d’avancement.',
    phrases: [
      'Autrement dit…',
      'Ce que je veux souligner, c’est…',
      'Je précise : …',
    ],
    exercise:
        'Expliquez un « tableau de bord » sans employer cette expression.',
    modelAnswer:
        'C’est un écran qui rassemble les principaux indicateurs pour voir rapidement si le travail avance comme prévu.',
    questions: [
      CourseQuestion(
        'Un mot précis vous manque. Que pouvez-vous faire ?',
        [
          'Décrire sa fonction et continuer',
          'Abandonner la réponse',
          'Recommencer jusqu’à ne plus hésiter',
        ],
        0,
        'Une paraphrase claire maintient la communication.',
      ),
      CourseQuestion(
        'Quel est le but de l’exercice en trois durées ?',
        [
          'Parler le plus vite possible',
          'Supprimer toute pause',
          'Sélectionner et organiser les idées essentielles',
        ],
        2,
        'La concision et l’organisation priment sur la vitesse.',
      ),
    ],
    speakingTask:
        'Expliquez un outil ou un processus sans utiliser son nom technique. Reformulez ensuite la même idée plus brièvement. Répondez enfin à une demande de clarification sans tout recommencer.',
    criteria: [
      'J’ai poursuivi malgré un mot manquant.',
      'J’ai gardé le sens en reformulant.',
      'J’ai amélioré l’organisation, pas seulement la vitesse.',
    ],
  ),
  CourseLesson(
    id: '16-transfer',
    module: 8,
    title: 'Bilan : transférer à une situation nouvelle',
    objective:
        'Combiner narration, opinion, nuance et hypothèse sans texte appris.',
    teaching: [
      'Le bilan réunit plusieurs tâches, mais ne produit pas une certification. Une réussite à des questions écrites ne mesure ni la compréhension de la parole réelle ni la prononciation.',
      'Choisissez un sujet professionnel nouveau et préparez seulement trois mots-clés. Expliquez la situation, défendez une option et répondez à une objection.',
      'Ajoutez une relance inattendue : budget réduit, délai raccourci ou avis opposé. Adaptez votre réponse plutôt que revenir au discours préparé.',
      'Comparez votre prestation à vos objectifs du début du parcours. Choisissez deux points à retravailler, reprenez les classes concernées et utilisez votre carnet d’erreurs. Un enseignant ou un interlocuteur compétent peut apporter une observation que l’autoévaluation ne fournit pas.',
    ],
    simpleExample:
        'Je connais le sujet, mais je ne sais pas répondre à une autre question.',
    developedExample:
        'Je maintiendrais l’objectif du projet, mais je réduirais sa portée si le budget diminuait. Nous pourrions d’abord traiter les demandes les plus fréquentes. Cette solution ne répondrait pas à tous les besoins; il faudrait donc expliquer clairement les critères de priorité.',
    phrases: [
      'Compte tenu de cette nouvelle contrainte…',
      'Je maintiendrais… mais je modifierais…',
      'Le point que je dois encore travailler est…',
    ],
    exercise:
        'Préparez trois mots-clés pour défendre un changement, puis imaginez une objection que vous n’aviez pas prévue.',
    modelAnswer:
        'Exemple de mots-clés : accès, soutien, essai. Objection : les petites équipes n’ont pas le temps de se former. Réponse possible : prévoir un accompagnement progressif plutôt qu’un lancement simultané.',
    questions: [
      CourseQuestion(
        'Terminer ce parcours signifie…',
        [
          'avoir obtenu officiellement C',
          'avoir réalisé les activités, sans certification de niveau',
          'ne plus avoir besoin de pratiquer',
        ],
        1,
        'Les badges de cours mesurent les activités réalisées, pas un résultat officiel.',
      ),
      CourseQuestion(
        'Une nouvelle contrainte apparaît. Quelle réponse montre un transfert des acquis ?',
        [
          'Réciter le texte initial',
          'Ignorer la contrainte',
          'Adapter sa recommandation et expliquer pourquoi',
        ],
        2,
        'Le transfert consiste à utiliser les outils appris dans une situation différente.',
      ),
    ],
    speakingTask:
        'Une organisation veut remplacer une partie de son accueil en personne par un service numérique. Expliquez l’enjeu, défendez une option, examinez une objection et imaginez ce qui changerait si le budget était réduit. Concluez par un résumé et une limite.',
    criteria: [
      'J’ai adapté ma réponse aux relances.',
      'J’ai combiné explication, opinion et hypothèse de façon cohérente.',
      'J’ai identifié deux priorités pour poursuivre mon apprentissage.',
    ],
  ),
];

CourseLesson courseLesson(String id) =>
    bToCLessons.firstWhere((lesson) => lesson.id == id);
