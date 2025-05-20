Class {
	#name : 'GitCodeCoverage',
	#superclass : 'Object',
	#instVars : [
		'gitImporter'
	],
	#category : 'Git-Code-Ownership-Objects',
	#package : 'Git-Code-Ownership',
	#tag : 'Objects'
}

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragInBranch:  fileBlameDict [ 
	|tree s  postOrderTraversal    |
"Création de l'arbre"
tree := HNode named: 'projet'.

"Création de l'échelle de couleur"
s := NSScale linear.
s domain: { -30 . 0 }.
s range: { Color white . Color red }.

"Construction de l'arbre avec les fichiers"
fileBlameDict associationsDo: [ :assoc |
    | path segments currentNode nextNode lastSegment isFile fileNode nodeName blames colors color |

    path := assoc key.
    blames := assoc value.
    segments := path asFileReference pathSegments.

    lastSegment := segments last.
    isFile := lastSegment includes: $. .  " pour éviter la création des fichier fantome pour des dossier "

    "Calcul des couleurs pour les fichiers"
   colors := (blames isArray 
    ifTrue: [ 
        blames collect: [ :d | 
            (s scale: ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)) translucent 
        ] 
    ] 
    ifFalse: [ 
        #()  "Return an empty collection if blames is not an array"
    ]).

    currentNode := tree.

    "Créer les dossiers intermédiaires"
    segments allButLast do: [ :segment |
        nodeName := segment , '/'.
        nextNode := (currentNode children detect: [ :child | child name = nodeName ] ifNone: [
            | newNode  |
             newNode := HNode named: nodeName  .
                newNode style: HBorderAndTitleStyle new. 
             currentNode add: newNode.
            newNode
        ]).
        currentNode := nextNode.
       currentNode collapse .
    ].

    "Ajouter un fichier seulement si c’est un vrai fichier"
isFile ifTrue: [
    fileNode := HNode named: lastSegment.
    color := (colors ifNotEmpty: [ colors sum translucent ] ifEmpty: [ Color gray translucent ]).
    fileNode color: color.
    fileNode rawModel: blames.  "💡 Ajoute les blames au nœud"
    currentNode add: fileNode.
].


].

"Parcours post-ordre pour colorier les dossiers"
postOrderTraversal := [ :node :block |
    node children do: [ :child |
        postOrderTraversal value: child value: block
    ].
    block value: node.
].

"Coloration des dossiers"
postOrderTraversal value: tree value: [ :node |
    | childColors averageColor |
    (node children isEmpty) ifFalse: [
        childColors := node children collect: [ :child | child color ].
        childColors := childColors select: [ :c | c notNil ].
        childColors isEmpty ifFalse: [
            averageColor := childColors sum / childColors size.
            node color: averageColor translucent.
        ].
    ].
].

"Afficher l'arbre"
tree open.

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragInBranch:  fileBlameDict  from:  starDate to: endDate [ 
	|tree s  postOrderTraversal    |
"Création de l'arbre"
tree := HNode named: 'projet'.

"Création de l'échelle de couleur"
s := NSScale linear.
s domain: { starDate . endDate  }.
s range: { Color blue . Color red }.

"Construction de l'arbre avec les fichiers"
fileBlameDict associationsDo: [ :assoc |
    | path segments currentNode nextNode lastSegment isFile fileNode nodeName blames colors color |

    path := assoc key.
    blames := assoc value.
    segments := path asFileReference pathSegments.

    lastSegment := segments last.
    isFile := lastSegment includes: $. .  " pour éviter la création des fichier fantome pour des dossier "

    "Calcul des couleurs pour les fichiers"
   colors := (blames isArray 
    ifTrue: [ 
        blames collect: [ :d | 
            (s scale: ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)) translucent 
        ] 
    ] 
    ifFalse: [ 
        #()  "Return an empty collection if blames is not an array"
    ]).

    currentNode := tree.

    "Créer les dossiers intermédiaires"
    segments allButLast do: [ :segment |
        nodeName := segment , '/'.
        nextNode := (currentNode children detect: [ :child | child name = nodeName ] ifNone: [
            | newNode  |
             newNode := HNode named: nodeName  .
                newNode style: HBorderAndTitleStyle new. 
             currentNode add: newNode.
            newNode
        ]).
        currentNode := nextNode.
       currentNode collapse .
    ].

    "Ajouter un fichier seulement si c’est un vrai fichier"
isFile ifTrue: [
    fileNode := HNode named: lastSegment.
    color := (colors ifNotEmpty: [ colors sum translucent ] ifEmpty: [ Color gray translucent ]).
    fileNode color: color.
    fileNode rawModel: blames.  "💡 Ajoute les blames au nœud"
    currentNode add: fileNode.
].


].

"Parcours post-ordre pour colorier les dossiers"
postOrderTraversal := [ :node :block |
    node children do: [ :child |
        postOrderTraversal value: child value: block
    ].
    block value: node.
].

"Coloration des dossiers"
postOrderTraversal value: tree value: [ :node |
    | childColors averageColor |
    (node children isEmpty) ifFalse: [
        childColors := node children collect: [ :child | child color ].
        childColors := childColors select: [ :c | c notNil ].
        childColors isEmpty ifFalse: [
            averageColor := childColors sum / childColors size.
            node color: averageColor translucent.
        ].
    ].
].

"Afficher l'arbre"
tree open.

]

{ #category : 'coverage' }
GitCodeCoverage >> codeCoveragInFile: blame [   
    | daysList h  |



    "1. Vérifier que le blame est valide"
    blame ifNil: [ ^self inform: 'Aucune information de blame fournie.' ].

    (blame isArray and: [ blame isEmpty ])
        ifTrue: [ ^self inform: 'Pas de commits trouvés dans ce blame.' ].

    "2. Extraire la liste des jours depuis les commits"
    daysList := blame collect: [ :d |
        ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)
    ].

    "3. Créer et configurer la heatmap"
    h := RSHeatmap new.
    h objectsX: (1 to: daysList size) asArray.
    h objectsY: #('Commits').
    h dataMatrix: (Array with: daysList asArray).
    h shouldShowCellLabels: false.
    h open.

]

{ #category : 'coverage' }
GitCodeCoverage >> codeCoverageOf: aGLHProject inBranch: aBranch [ 

	gitImporter importFilesOfBranch: aBranch.
]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> fileBlamesDictOfBranch: GLHBranch [ 
   |files blames fileBlameDict|  
      blames  := nil . 
      fileBlameDict := Dictionary new.
      files := ((GLHBranch allToScope: GLHFile))asOrderedCollection .
      blames := files collect: [ :file | gitImporter getBlameOf: file path  inBranch: ((GLHBranch  name )asStringOrText) ofProject:GLHBranch repository  project id ].
     files with: blames do: [ :file :blame | 
    | value |
    value := (blame isNil or: [blame isEmpty]) 
        ifTrue: ['No Blame Found'] 
        ifFalse: [blame].
    fileBlameDict at: file path put: value.
].
^fileBlameDict.

]

{ #category : 'accessing' }
GitCodeCoverage >> importer: aGitImporter [ 
	gitImporter := aGitImporter 
]
