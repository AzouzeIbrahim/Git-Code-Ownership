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
GitCodeCoverage >> codeCoveragInBranch: fileBlameDict [ 
	|tree s  postOrderTraversal |
"Création de l'arbre"
tree := HNode named: 'projet'.

"Création de l'échelle de couleur en fonction de l'ancienneté"
s := NSScale linear.
s domain: { -30 . 0 }.
s range: { Color blue . Color red }.

"Construction de l'arbre avec les fichiers"
fileBlameDict associationsDo: [ :assoc |
    | path blames    segments currentNode nextNode lastSegment nodeName isFile fileNode  color   colors |

    path := assoc key.
    blames := assoc value.
    segments := path asFileReference pathSegments.

    "Calculer les couleurs pour le fichier"
    colors := blames collect: [ :d |
        (s scale: ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)) translucent
    ].

    currentNode := tree.
    lastSegment := segments last.
    isFile := segments size = 1 or: [ segments last ~= '' ].

    "Naviguer dans la hiérarchie (dossiers)"
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

    "Créerles nodes de  fichier ou sous-dossier"
    nodeName := isFile ifTrue: [ lastSegment ] ifFalse: [ lastSegment , '/' ].
    fileNode := HNode named: nodeName.

    "Colorier si c'est un fichier"
    isFile ifTrue: [
        color := (colors ifNotEmpty: [ colors sum translucent ] ifEmpty: [ Color gray translucent ]).
        fileNode color: color.
    ].

    currentNode add: fileNode.
].

"Définir une méthode récursive pour parcourir en post-ordre"
postOrderTraversal := [ :node :block |
    node children do: [ :child |
        postOrderTraversal value: child value: block
    ].
    block value: node.
].

"Appliquer la couleur aux dossiers"
postOrderTraversal value: tree value: [ :node |
    | childColors averageColor |
    (node children isEmpty) ifFalse: [
        "Récupérer les couleurs de tous les enfants qui ont une couleur"
        childColors := node children collect: [ :child | child color ].
        childColors := childColors select: [ :c | c notNil ].

        childColors isEmpty ifFalse: [
            "Calculer la couleur moyenne"
            averageColor := childColors sum / childColors size.
            node color: averageColor translucent.
        ].
    ].
].


"Afficher l'arbre"
tree open .

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

{ #category : 'accessing' }
GitCodeCoverage >> importer: aGitImporter [ 
	gitImporter := aGitImporter 
]
