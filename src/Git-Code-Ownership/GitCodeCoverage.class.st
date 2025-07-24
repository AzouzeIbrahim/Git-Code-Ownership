Class {
	#name : 'GitCodeCoverage',
	#superclass : 'Object',
	#instVars : [
		'gitImporter',
		'project',
		'branch',
		'glApi',
		'glhImporter',
		'fileBlameDict',
		'developerEmail',
		'maxDays',
		'color'
	],
	#category : 'Git-Code-Ownership-Objects',
	#package : 'Git-Code-Ownership',
	#tag : 'Objects'
}

{ #category : 'coverage' }
GitCodeCoverage >> HeatMapForContributorEmail: authorEmail usingColor: baseColor [ 
    | tree blames devDict getDevPercent postOrderTraversal |
    tree := self  ProjectTree.
    blames := tree allChildren collect: [:node | node rawModel] thenSelect: [:each | each isArray and: [each notEmpty]].
    devDict := glhImporter  UserContributionFromBlames: blames.

    getDevPercent := [:blames :email |
        | total matching |
        total := blames size.
        matching := blames count: [:b | ((b at: 'commit') at: 'author_email') = email].
        total = 0 ifTrue: [0] ifFalse: [matching / total asFloat].
    ].

    tree allChildren do: [:fileNode |
        | percent color |
        (fileNode rawModel isArray and: [fileNode rawModel notEmpty]) ifTrue: [
            percent := getDevPercent value: fileNode rawModel value: authorEmail.
            color := percent > 0 ifTrue: [baseColor alpha: percent] ifFalse: [Color gray].
            fileNode color: color.
        ].
    ].

    postOrderTraversal := [:node :block |
        node children do: [:child | postOrderTraversal value: child value: block].
        block value: node.
    ].

    postOrderTraversal value: tree value: [:node |
        | descendantFiles percents avgPercent color |
        descendantFiles := node allChildren select: [:child |
            child rawModel isArray and: [child rawModel notEmpty]
        ].
        descendantFiles isEmpty ifFalse: [
            percents := descendantFiles collect: [:child |
                getDevPercent value: child rawModel value: authorEmail
            ].
            avgPercent := percents sum / percents size asFloat.
            color := avgPercent > 0 ifTrue: [baseColor alpha: avgPercent] ifFalse: [Color gray].
            node color: color.
        ].
    ].
    ^ tree

]

{ #category : 'coverage' }
GitCodeCoverage >> HeatMapForRecentChangesUpToDays: daysAgo [
    | tree scale postOrderTraversal calculateDaysAgo |
    tree := self ProjectTree.
    scale := NSScale linear.
    scale domain: { 0 . daysAgo }.
    scale range: { Color red . Color blue }.
    scale clamp: true.

    calculateDaysAgo := [:blames |
        | latestDate |
        latestDate := (blames collect: [:d | DateAndTime fromString: ((d at: #commit) at: #committed_date)]) max.
        (Date today - latestDate) asDays
    ].

    tree children do: [:child |
        (child rawModel isArray and: [child rawModel notEmpty]) ifTrue: [
            | days color |
            days := calculateDaysAgo value: child rawModel.
            color := (scale scale: days) translucent.
            child color: color.
        ].
    ].

    postOrderTraversal := [:node :block |
        node children do: [:child | postOrderTraversal value: child value: block].
        block value: node.
    ].

    postOrderTraversal value: tree value: [:node |
        | descendantFiles daysList avgDays color |
        descendantFiles := node allChildren select: [:child |
            child rawModel isArray and: [child rawModel notEmpty]
        ].
        descendantFiles isEmpty ifFalse: [
            daysList := descendantFiles collect: [:child |
                calculateDaysAgo value: child rawModel
            ].
            avgDays := daysList sum / daysList size.
            color := (scale scale: avgDays) translucent.
            node color: color.
        ].
    ].
    ^ tree
]

{ #category : 'coverage' }
GitCodeCoverage >> HeatMapForTop3Contributors [
  | tree blames devDict topAuthors topAuthorEmails developerColors postOrderTraversal mainContributor |

    tree := self ProjectTree .

    blames := tree allChildren
        collect: [:node | node rawModel]
        thenSelect: [:each | each isArray and: [each notEmpty]].

    devDict := glhImporter UserContributionFromBlames: blames.

    topAuthors := (devDict associations
        sort: [:a :b | b value < a value])
        first: (3 min: devDict size).

    topAuthorEmails := topAuthors collect: [:assoc | assoc key].

    developerColors := Dictionary new.
    topAuthorEmails withIndexDo: [:author :index |
        developerColors at: author put: ({ Color red. Color green. Color blue } at: index ifAbsent: [Color gray ])].
    developerColors at: 'Others' put: Color gray.

    mainContributor := [:blamesList |
        | authorCounts maxAuthor |
        authorCounts := Dictionary new.
        blamesList do: [:line |
            | author |
            author := ((line at: #commit) at: #author_email).
            authorCounts at: author ifAbsentPut: [0].
            authorCounts at: author put: (authorCounts at: author) + 1.
        ].
        maxAuthor := authorCounts associations
            inject: nil into: [:max :each |
                (max isNil or: [each value > max value])
                    ifTrue: [each] ifFalse: [max]].
        maxAuthor key
    ].

    tree allChildren do: [:fileNode |
        | contributor key color |
        (fileNode rawModel isArray and: [fileNode rawModel notEmpty]) ifTrue: [
            contributor := mainContributor value: fileNode rawModel.
            key := (topAuthorEmails includes: contributor)
                ifTrue: [contributor]
                ifFalse: ['Others'].
            color := (developerColors at: key ifAbsent: [Color gray]) translucent.
            fileNode color: color.
        ].
    ].

    postOrderTraversal := [:node :block |
        node children do: [:child | postOrderTraversal value: child value: block].
        block value: node.
    ].

    postOrderTraversal value: tree value: [:node |
        | descendantFiles authorCounts maxAuthor contributor key color |
        descendantFiles := node allChildren select: [:child |
            child rawModel isArray and: [child rawModel notEmpty]].
        descendantFiles isEmpty ifFalse: [
            authorCounts := Dictionary new.
            descendantFiles do: [:child |
                contributor := mainContributor value: child rawModel.
                key := (topAuthorEmails includes: contributor)
                    ifTrue: [contributor]
                    ifFalse: ['Others'].
                authorCounts at: key ifAbsentPut: [0].
                authorCounts at: key put: (authorCounts at: key) + 1.
            ].
            maxAuthor := authorCounts associations
                inject: nil into: [:max :each |
                    (max isNil or: [each value > max value])
                        ifTrue: [each] ifFalse: [max]].
            color := (developerColors at: maxAuthor key ifAbsent: [Color gray]) translucent.
            node color: color.
        ].
    ].

    ^ tree
]

{ #category : 'initialization - data' }
GitCodeCoverage >> ProjectTree [ 
  | root |
    root := HNode named: 'projet'.
    fileBlameDict associationsDo: [:assoc |
        | path segments currentNode lastSegment isFile blames fileNode nodeName |
        path := assoc key.
        blames := assoc value.
        segments := path asFileReference pathSegments.
        lastSegment := segments last.
        isFile := lastSegment includes: $. .
        currentNode := root.
        segments allButLast do: [:segment |
            nodeName := segment , '/'.
            currentNode := currentNode children
                detect: [:child | child name = nodeName ]
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

{ #category : 'accessing' }
GitCodeCoverage >> branch [
	^ branch
]

{ #category : 'accessing' }
GitCodeCoverage >> branch: aBranchName [
	branch := aBranchName.
	^ self
]

{ #category : 'accessing' }
GitCodeCoverage >> fileBlameDict [
	^ fileBlameDict
]

{ #category : 'accessing' }
GitCodeCoverage >> fileBlameDict: afileBlameDict [
	fileBlameDict := afileBlameDict.
	^ self
]

{ #category : 'initialization - data' }
GitCodeCoverage >> fileBlamesDictOfBranch [   
    | files blames  |
 files := nil .
    files := (branch allToScope: GLHFile) asOrderedCollection.
    blames := files collect: [:file |
        gitImporter getBlameOf: file path inBranch: branch name asStringOrText ofProject: branch repository project id
    ].
    fileBlameDict := Dictionary new.
    files with: blames do: [:file :blame |
        fileBlameDict at: file path put: ((blame isNil or: [blame isEmpty]) ifTrue: ['No Blame Found'] ifFalse: [blame])
    ].
    ^ fileBlameDict

]

{ #category : 'accessing' }
GitCodeCoverage >> glApi [
	^ glApi
]

{ #category : 'accessing' }
GitCodeCoverage >> glApi: anApi [
	glApi := anApi.
	^ self
]

{ #category : 'accessing' }
GitCodeCoverage >> glhImporter [
	^ glhImporter
]

{ #category : 'accessing' }
GitCodeCoverage >> glhImporter: anImporter [
	glhImporter := anImporter.
	^ self
]

{ #category : 'accessing' }
GitCodeCoverage >> importer: aGitImporter [ 
	gitImporter := aGitImporter 
]

{ #category : 'accessing' }
GitCodeCoverage >> project [
	^ project
]

{ #category : 'accessing' }
GitCodeCoverage >> project: aProject [
	project := aProject.
	^ self
]
