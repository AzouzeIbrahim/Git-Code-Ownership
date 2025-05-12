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
    colors := blames collect: [ :d |
        (s scale: ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)) translucent
    ].

    currentNode := tree.

    "Créer les dossiers intermédiaires"
    segments allButLast do: [ :segment |
        nodeName := segment , '/'.
        nextNode := (currentNode children detect: [ :child | child name = nodeName ] ifNone: [
            | newNode |
            newNode := HNode named: nodeName.
            currentNode add: newNode.
            newNode
        ]).
        currentNode collapse.
        currentNode := nextNode.
    ].

    "Ajouter un fichier seulement si c’est un vrai fichier"
    isFile ifTrue: [
        fileNode := HNode named: lastSegment.
        color := (colors ifNotEmpty: [ colors sum translucent ] ifEmpty: [ Color gray translucent ]).
        fileNode color: color.
        currentNode add: fileNode.
    ].

    currentNode collapse.
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
                       |files blames fileBlameDict  |


      files := ((GLHBranch allToScope: GLHFile))asOrderedCollection .
      blames := files collect: [ :file | gitImporter getBlameOf: file path  inBranch: ((GLHBranch  name )asStringOrText) ofProject:GLHBranch repository  project id ].
     fileBlameDict := Dictionary new.
    files with: blames do: [ :file :blame | fileBlameDict at: file put: (blame ifNil: ['No Blame Found'])].
^fileBlameDict .
]

{ #category : 'accessing' }
GitCodeCoverage >> importer: aGitImporter [ 
	gitImporter := aGitImporter 
]
