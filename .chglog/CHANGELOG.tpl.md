---
layout: default
title: Changelog
---

{{ if .Versions -}}
<a name="unreleased"></a>
## [Unreleased]

{{ if .Unreleased.CommitGroups -}}
{{ range .Unreleased.CommitGroups -}}
{{ range .Commits -}}
- {{ .Header }}
{{ end }}
{{ end -}}
{{ end -}}
{{ end -}}

{{ range .Versions }}
## {{ if .Tag.Previous -}}[{{ .Tag.Name }}]({{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}){{ else }}{{ .Tag.Name }}{{ end }} - {{ datetime "2006-01-02" .Tag.Date }}

{{ range .CommitGroups -}}
{{ range .Commits -}}
- {{ .Header }}
{{ end }}
{{ end -}}

{{- if .RevertCommits -}}
{{ range .RevertCommits -}}
- {{ .Revert.Header }}
{{ end }}
{{ end -}}

{{- if .MergeCommits -}}
{{ range .MergeCommits -}}
- {{ .Header }}
{{ end }}
{{ end -}}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}
### {{ .Title }}
{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}
{{ end -}}
