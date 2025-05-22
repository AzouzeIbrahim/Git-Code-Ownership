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
	|tree s  postOrderTraversal calculateDaysAgo   |
"Initialisation de l’arbre racine"
tree := HNode named: 'projet'.

"Création de l’échelle de couleur"
s := NSScale linear.
s domain: { 0 . 30 }.
s range: { Color red . Color blue }.
s clamp: true.

"Fonction utilitaire pour calculer la durée  à partir des blames"
calculateDaysAgo := [ :blames |
    | latestDate |
    latestDate := (blames collect: [ :d |
        DateAndTime fromString: ((d at: #commit) at: #committed_date)
    ]) max.
    (Date today - latestDate) asDays
].

"Construction de l’arbre à partir des fichiers"
fileBlameDict associationsDo: [ :assoc |
    | path segments currentNode lastSegment isFile blames fileNode nodeName color |

    path := assoc key.
    blames := assoc value.
    segments := path asFileReference pathSegments.
    lastSegment := segments last.
    isFile := lastSegment includes: $. .  

    currentNode := tree.

    "Création des dossiers intermédiaires"
    segments allButLast do: [ :segment |
        nodeName := segment , '/'.
        currentNode := currentNode children
            detect: [ :child | child name = nodeName ]
            ifNone: [
                | newNode |
                newNode := HNode named: nodeName.
                newNode style: HBorderAndTitleStyle new.
                currentNode add: newNode.
                newNode
            ].
        currentNode collapse.
    ].

    isFile ifTrue: [
        fileNode := HNode named: lastSegment.

        color := (blames isArray and: [ blames notEmpty ])
            ifTrue: [
                (s scale: (calculateDaysAgo value: blames)) translucent
            ]
            ifFalse: [ Color gray translucent ].

        fileNode color: color.
        fileNode rawModel: blames.
        currentNode add: fileNode.
    ].
].

"Coloration récursive des dossiers par moyenne des daysAgo"
postOrderTraversal := [ :node :block |
    node children do: [ :child |
        postOrderTraversal value: child value: block
    ].
    block value: node.
].

postOrderTraversal value: tree value: [ :node |
    | descendantFiles daysList avgDays color |

    descendantFiles := node allChildren select: [ :child |
        (child rawModel isArray and: [ child rawModel notEmpty ])
    ].

    descendantFiles isEmpty ifFalse: [
        daysList := descendantFiles collect: [ :child |
            calculateDaysAgo value: child rawModel
        ].
        avgDays := daysList sum / daysList size.
        color := (s scale: avgDays) translucent.
        node color: color.
    ].
].

"Affiche l’arbre"
tree open.

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragInBranch:  fileBlameDict  from:  starDate to: endDate [ 
	|tree s  postOrderTraversal  calculateDaysAgo   |
"Création de l'arbre"
tree := HNode named: 'projet'.

"Création de l'échelle de couleur"
s := NSScale linear.
s domain: { starDate . endDate  }.
s range: { Color red . Color blue }.
s clamp: true. 

"Fonction utilitaire pour calculer la durée  à partir des blames"
calculateDaysAgo := [ :blames |
    | latestDate |
    latestDate := (blames collect: [ :d |
        DateAndTime fromString: ((d at: #commit) at: #committed_date)
    ]) max.
    (Date today - latestDate) asDays
].

"Construction de l’arbre à partir des fichiers"
fileBlameDict associationsDo: [ :assoc |
    | path segments currentNode lastSegment isFile blames fileNode nodeName color |

    path := assoc key.
    blames := assoc value.
    segments := path asFileReference pathSegments.
    lastSegment := segments last.
    isFile := lastSegment includes: $. .  

    currentNode := tree.

    "Création des dossiers intermédiaires"
    segments allButLast do: [ :segment |
        nodeName := segment , '/'.
        currentNode := currentNode children
            detect: [ :child | child name = nodeName ]
            ifNone: [
                | newNode |
                newNode := HNode named: nodeName.
                newNode style: HBorderAndTitleStyle new.
                currentNode add: newNode.
                newNode
            ].
        currentNode collapse.
    ].

    isFile ifTrue: [
        fileNode := HNode named: lastSegment.

        color := (blames isArray and: [ blames notEmpty ])
            ifTrue: [
                (s scale: (calculateDaysAgo value: blames)) translucent
            ]
            ifFalse: [ Color gray translucent ].

        fileNode color: color.
        fileNode rawModel: blames.
        currentNode add: fileNode.
    ].
].

"Coloration récursive des dossiers par moyenne des daysAgo"
postOrderTraversal := [ :node :block |
    node children do: [ :child |
        postOrderTraversal value: child value: block
    ].
    block value: node.
].

postOrderTraversal value: tree value: [ :node |
    | descendantFiles daysList avgDays color |

    descendantFiles := node allChildren select: [ :child |
        (child rawModel isArray and: [ child rawModel notEmpty ])
    ].

    descendantFiles isEmpty ifFalse: [
        daysList := descendantFiles collect: [ :child |
            calculateDaysAgo value: child rawModel
        ].
        avgDays := daysList sum / daysList size.
        color := (s scale: avgDays) translucent.
        node color: color.
    ].
].

"Affiche l’arbre"
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
       files := nil .
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
