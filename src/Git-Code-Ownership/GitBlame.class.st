Class {
	#name : 'GitBlame',
	#superclass : 'Object',
	#instVars : [
		'commit',
		'lines',
		'file'
	],
	#category : 'Git-Code-Ownership-Objects',
	#package : 'Git-Code-Ownership',
	#tag : 'Objects'
}

{ #category : 'accessing' }
GitBlame >> commit [

	^ commit
]

{ #category : 'accessing' }
GitBlame >> commit: anObject [

	commit := anObject
]

{ #category : 'accessing' }
GitBlame >> creator [
	^ commit ifNotNil: #author
]

{ #category : 'accessing' }
GitBlame >> file [

	^ file
]

{ #category : 'accessing' }
GitBlame >> file: anObject [

	file := anObject
]

{ #category : 'accessing' }
GitBlame >> lines [

	^ lines
]

{ #category : 'accessing' }
GitBlame >> lines: anObject [

	lines := anObject
]
