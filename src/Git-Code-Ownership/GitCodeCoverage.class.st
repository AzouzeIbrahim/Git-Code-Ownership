Class {
	#name : 'GitCodeCoverage',
	#superclass : 'Object',
	#instVars : [
		'gitImporter',
		'project',
		'branch',
		'glApi',
		'glhImporter',
		'fileBlameDict'
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

     "Define a  function to calculate the contribution percentage of the given author in a blame list"
    getDevPercent := [:blames :email |
        | total matching |
        total := blames size.
        matching := blames count: [:b | ((b at: 'commit') at: 'author_email') = email].
        total = 0 ifTrue: [0] ifFalse: [matching / total asFloat].
    ].

    " Color each file node based on the author's contribution"
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

   " For each directory , compute the average contribution over its descendant files"
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
    " Create a linear color scale from 0 to daysAgo, mapping to red (recent) to blue (old)"
    scale := NSScale linear.
    scale domain: { 0 . daysAgo }.
    scale range: { Color red . Color blue }.
    scale clamp: true.

    calculateDaysAgo := [:blames |
        | latestDate |
        latestDate := (blames collect: [:d | DateAndTime fromString: ((d at: #commit) at: #committed_date)]) max.
        (Date today - latestDate) asDays
    ].
     " Color each file node (leaf) based on how recent the latest change was"
    tree children do: [:child |
        (child rawModel isArray and: [child rawModel notEmpty]) ifTrue: [
            | days color |
            days := calculateDaysAgo value: child rawModel.
            color := (scale scale: days) translucent.
            child color: color.
        ].
    ].
    " Define post-order traversal to color folder nodes based on average recency of their children"
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
     blames := tree allChildren
        collect: [:node | node rawModel]
        thenSelect: [:each | each isArray and: [each notEmpty]].

    "getting  a dictionary of  contributor (email → number of contributions)"
    devDict := glhImporter UserContributionFromBlames: blames.
    " Extract the top 3 contributors sorted by number of contributions "
    topAuthors := (devDict associations
        sort: [:a :b | b value < a value])
        first: (3 min: devDict size).
    topAuthorEmails := topAuthors collect: [:assoc | assoc key].

    "Assign a distinct color for each top contributor (up to 3), others get gray"
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

    " Apply color to each file node based on its main contributor"
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

    "Define post-order traversal for 'non-leaf' nodes to aggregate colors"
    postOrderTraversal := [:node :block |
        node children do: [:child | postOrderTraversal value: child value: block].
        block value: node.
    ].

    "Color folder nodes based on their dominant contributor from their descendant files"
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
 "This function creates the tree of a project based on the file paths, where each file or directory is a node, and each file is associated with its blames."
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
        "create the tree"
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
        "associate files  with its blames"
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

     "This function creates a dictionary where the key is the file path and the value is the blames of the file." 
    | files blames  |
    files := nil .

    "Getting all the blames and the files and of a project from a specific branch"
    files := (branch allToScope: GLHFile) asOrderedCollection.
    blames := files collect: [:file |
        gitImporter getBlameOf: file path inBranch: branch name asStringOrText ofProject: branch repository project id
    ].

    "Associate each file with its blames if they exist"
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
