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
GitCodeCoverage >> codeCoveragFor: AuthorEmail from: fileBlameDict by: color [
    | blames projectTree  developerContributionDict developerColor getDevPercent postOrderTraversal |


      projectTree := self ProjectTree: fileBlameDict .
      blames := projectTree allChildren collect: [:fileNode | fileNode rawModel] thenSelect: [:each | each isArray and: [each notEmpty]].
      developerContributionDict := gitImporter UserContributionFromBlames: blames .
      developerColor := color . 

     getDevPercent := [ :blames :authorEmail |
        | total matching |
        total := blames size.
        matching := blames count: [ :b |
            ((b at: 'commit') at: 'author_email') = authorEmail
        ].
        total = 0 ifTrue: [ 0 ] ifFalse: [ matching / total asFloat ].
    ].

    projectTree allChildren do: [ :fileNode |
        | blames percent color |
        blames := fileNode rawModel.
        (blames isArray and: [ blames notEmpty ]) ifTrue: [
            percent := getDevPercent value: blames value: AuthorEmail.
            percent > 0 ifTrue: [
                color := developerColor alpha: percent.
                fileNode color: color.
            ] ifFalse: [
                fileNode color: Color gray.
            ].
        ].
    ].
    postOrderTraversal := [ :node :block |
        node children do: [ :child |
            postOrderTraversal value: child value: block
        ].
        block value: node.
    ].

    postOrderTraversal value: projectTree value: [ :node |
        | descendantFiles percents avgPercent color |
        descendantFiles := node allChildren select: [ :child |
            child rawModel isArray and: [ child rawModel notEmpty ]
        ].
        descendantFiles isEmpty ifFalse: [
            percents := descendantFiles collect: [ :child |
                getDevPercent value: child rawModel value: AuthorEmail
            ].
            avgPercent := percents sum / percents size asFloat.
            avgPercent > 0 ifTrue: [
                color := developerColor alpha: avgPercent.
                node color: color.
            ] ifFalse: [
                node color: Color gray.
            ].
        ].
    ].
     ^ projectTree .

]

{ #category : 'as yet unclassified' }
GitCodeCoverage >> codeCoveragForTop3Contributeurs:   fileBlameDict [  
    | projectTree developerContributionDict topAuthors topAuthorNames developerColors postOrderTraversal blames mainContributor |

    projectTree := self ProjectTree: fileBlameDict.
    blames := projectTree allChildren collect: [:fileNode | fileNode rawModel] thenSelect: [:each | each isArray and: [each notEmpty]].
    developerContributionDict := gitImporter UserContributionFromBlames: blames.

    "  Function to find the main contributor in a file"
    mainContributor := [ :blamesList |
        | authorCounts maxAuthor |
        authorCounts := Dictionary new.
        blamesList do: [ :line |
            | author |
            author := ((line at: #commit) at: #author_email).
            authorCounts at: author ifAbsentPut: [ 0 ].
            authorCounts at: author put: (authorCounts at: author) + 1.
        ].
        maxAuthor := authorCounts associations
            inject: nil into: [ :max :each |
                (max isNil or: [ each value > max value ])
                    ifTrue: [ each ] ifFalse: [ max ]
            ].
        maxAuthor key
    ].

    " top 3"
    topAuthors := (developerContributionDict associations
        sort: [ :a :b | b value < a value ])
        first: (3 min: developerContributionDict size).
    topAuthorNames := topAuthors collect: [ :assoc | assoc key ].

    " Assign colors "
    developerColors := Dictionary new.
    topAuthorNames withIndexDo: [ :author :index |
        developerColors at: author put: ({ Color red. Color green. Color blue } at: index ifAbsent: [ Color gray ]) ].
    developerColors at: 'Autres' put: Color gray.

    " Color files"
    projectTree allChildren do: [ :fileNode |
        | contributor key color |
        (fileNode rawModel isArray and: [ fileNode rawModel notEmpty ]) ifTrue: [
            contributor := mainContributor value: fileNode rawModel.
            key := (topAuthorNames includes: contributor)
                ifTrue: [ contributor ]
                ifFalse: [ 'Autres' ].
            color := (developerColors at: key ifAbsent: [ Color gray ]) translucent.
            fileNode color: color.
        ].
    ].

    postOrderTraversal := [ :node :block |
        node children do: [ :child |
            postOrderTraversal value: child value: block
        ].
        block value: node.
    ].

    postOrderTraversal value: projectTree value: [ :node |
        | descendantFiles authorCounts maxAuthor contributor key color |
        descendantFiles := node allChildren select: [ :child |
            child rawModel isArray and: [ child rawModel notEmpty ]
        ].
        descendantFiles isEmpty ifFalse: [
            authorCounts := Dictionary new.
            descendantFiles do: [ :child |
                contributor := mainContributor value: child rawModel.
                key := (topAuthorNames includes: contributor)
                    ifTrue: [ contributor ]
                    ifFalse: [ 'Autres' ].
                authorCounts at: key ifAbsentPut: [ 0 ].
                authorCounts at: key put: (authorCounts at: key) + 1.
            ].
            maxAuthor := authorCounts associations
                inject: nil into: [ :max :each |
                    (max isNil or: [ each value > max value ])
                        ifTrue: [ each ]
                        ifFalse: [ max ]
                ].
            color := (developerColors at: maxAuthor key ifAbsent: [ Color gray ]) translucent.
            node color: color.
        ].
    ].
    ^ { projectTree. developerColors }


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
