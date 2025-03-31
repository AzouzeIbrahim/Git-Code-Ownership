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
GitCodeCoverage >> codeCoveragInBranch: aGLHBranch [ 
	
	"aGLHBranch files collect: [ :file |
		self codeCoveragInFile: file ]."
]

{ #category : 'coverage' }
GitCodeCoverage >> codeCoveragInFile: aGLHFileDirectory [ 
	self shouldBeImplemented.
]

{ #category : 'coverage' }
GitCodeCoverage >> codeCoverageOf: aGLHProject inBranch: aBranch [ 

	gitImporter importFilesOfBranch: aBranch.
]

{ #category : 'accessing' }
GitCodeCoverage >> importer: aGitImporter [ 
	gitImporter := aGitImporter 
]
