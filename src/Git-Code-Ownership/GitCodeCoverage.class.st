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
GitCodeCoverage >> ProjectTree: fileBlameDict [ 
    | root |
    root := HNode named: 'projet'.
    
    fileBlameDict associationsDo: [ :assoc |
        | path segments currentNode lastSegment isFile blames fileNode nodeName |
        
        path := assoc key.
        blames := assoc value.
        segments := path asFileReference pathSegments.
        lastSegment := segments last.
        isFile := lastSegment includes: $. .
        
        currentNode := root.
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
            fileNode rawModel: blames. 
            currentNode add: fileNode.
        ].
    ].
    
    ^ root

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragInBranch:  fileBlameDict [ 
	|tree s  postOrderTraversal calculateDaysAgo |
     tree  := self ProjectTree: fileBlameDict .

      s := NSScale linear.
      s domain: { 0 . 30 }.
      s range: { Color red . Color blue }.
      s clamp: true.

calculateDaysAgo := [ :blames |
     | latestDate |
   latestDate := (blames collect: [ :d | DateAndTime fromString: ((d at: #commit) at: #committed_date) ]) max.
   (Date today - latestDate) asDays ].
tree children do: [:child |
        (child rawModel isArray and: [ child rawModel notEmpty ]) ifTrue: [
            | days color |
            days := calculateDaysAgo value: child rawModel.
            color := (s scale: days) translucent.
            child color: color.
        ].
    ].
postOrderTraversal := [ :node :block |
    node children do: [ :child | postOrderTraversal value: child value: block
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

^tree.

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragInBranch:  fileBlameDict  from:   DaysAgo [ 
	|tree s  postOrderTraversal  calculateDaysAgo   |

     tree  := self ProjectTree: fileBlameDict .
		s := NSScale linear.
		s domain: { 0 . DaysAgo  }.
		s range: { Color red . Color blue }.
		s clamp: true. 

calculateDaysAgo := [ :blames |
    | latestDate |
    latestDate := (blames collect: [ :d | DateAndTime fromString: ((d at: #commit) at: #committed_date)]) max.
    (Date today - latestDate) asDays
].
tree children do: [:child |
        (child rawModel isArray and: [ child rawModel notEmpty ]) ifTrue: [
            | days color |
            days := calculateDaysAgo value: child rawModel.
            color := (s scale: days) translucent.
            child color: color.
        ].
    ].

postOrderTraversal := [ :node :block |
    node children do: [ :child |postOrderTraversal value: child value: block].
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

^ tree .

]

{ #category : 'coverage' }
GitCodeCoverage >> codeCoveragInFile: blame [   
    | daysList h  |

    blame ifNil: [ ^self inform: 'No blames found ' ].
    (blame isArray and: [ blame isEmpty ])
        ifTrue: [ ^self inform: 'no commit found ' ].

    " calculate the periode in days "
    daysList := blame collect: [ :d |
        ((Date today - (DateAndTime fromString: ((d at: #commit) at: #committed_date))) asDays)
    ].

    " heatmap"
    h := RSHeatmap new.
    h objectsX: (1 to: daysList size) asArray.
    h objectsY: #('Commits').
    h dataMatrix: (Array with: daysList asArray).
    h shouldShowCellLabels: false.
    h open.

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> fileBlamesDictOfBranch: branch [  
   |files blames fileBlameDict|  
       blames  := nil . 
       files := nil .
      fileBlameDict := Dictionary new.
      files := ((branch allToScope: GLHFile))asOrderedCollection .
      blames := files collect: [ :file | gitImporter getBlameOf: file path  inBranch: ((branch  name )asStringOrText) ofProject: branch repository  project id ].
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
