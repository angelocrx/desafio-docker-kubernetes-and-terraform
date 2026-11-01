{{/*
Retorna o nome truncado e limpo do chart.
*/}}
{{- define "mural.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Cria um nome completo padrão para os recursos.
O Kubernetes limita nomes a 63 caracteres por conta da especificação de DNS.
Se o nome do release já contiver o nome do chart, ele usa o nome do release; 
caso contrário, junta ambos (release-chart).
*/}}
{{- define "mural.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Rótulos (Labels) comuns que devem ser aplicados em todos os recursos.
Identificam o chart, a versão, a instância e a ferramenta de gerenciamento (Helm).
*/}}
{{- define "mural.labels" -}}
helm.sh/chart: {{ include "mural.name" . }}
{{ include "mural.selectorLabels" . }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Rótulos (Labels) de seleção usados para vincular Services aos seus Pods e Deployments.
*/}}
{{- define "mural.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mural.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}