# Lab 08 - Configurazione S3, Lifecycle Management e Versioning

## Obiettivo

- Focus operativo: creare un bucket S3 con versioning attivo e una regola di lifecycle, verificando che una sovrascrittura o eliminazione non causi la perdita definitiva dei dati.
- Deliverable atteso: bucket con versioning attivo, almeno due versioni documentate di un file, regola di lifecycle configurata, evidenza del delete marker.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 08 registrato): bucket `demo-vm-reti-storage-<iniziali>-2026`, file di test `report.txt`, regola di lifecycle `demo-lifecycle-standard-ia`.


## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base del concetto di bucket, oggetto e chiave in S3.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare la policy di lifecycle e versioning pianificata su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve proteggere una cartella di documenti di progetto da sovrascritture accidentali, mantenendo sotto controllo i costi di storage nel tempo.
- Devi creare un bucket S3 con un nome univoco globale, attivare il versioning e configurare una regola di lifecycle che gestisca le versioni vecchie.
- Devi verificare che una sovrascrittura di un file generi una nuova versione, senza perdere la versione precedente.

## Step

1. Creare il bucket **demo-vm-reti-storage-<iniziali>-2026** (nome univoco globale) nella regione abilitata del Learner Lab.
2. Attivare il **Bucket Versioning** sul bucket appena creato.
3. Caricare `report.txt` e annotare il **Version ID** generato.
4. Modificare `report.txt` localmente e ricaricarlo con lo stesso nome: verificare che venga creata una seconda versione, visibile con **Show versions** attivo.
5. Configurare la regola di lifecycle **demo-lifecycle-standard-ia**: transizione delle versioni non correnti a Standard-IA dopo 30 giorni.
6. Eliminare `report.txt` (senza selezionare una versione specifica) e confermare scrivendo `permanently delete`: verificare che, con **Show versions** attivo, l'oggetto non sia realmente sparito ma abbia ricevuto un **delete marker**.
7. Documentare i Version ID, la regola di lifecycle, poi eseguire il cleanup completo.

## Esempio di deliverable compilato

|    # | Elemento            | Evidenza sintetica                                                          |
| ---: | ------------------- | --------------------------------------------------------------------------- |
|    1 | Bucket              | `demo-vm-reti-storage-<iniziali>-2026`, versioning `Enabled`                |
|    2 | Versione 1          | `report.txt`, Version ID `abc123...` (contenuto originale)                  |
|    3 | Versione 2          | `report.txt`, Version ID `def456...` (contenuto modificato)                 |
|    4 | Regola di lifecycle | `demo-lifecycle-standard-ia`: transizione a Standard-IA dopo 30 giorni      |
|    5 | Eliminazione        | delete marker aggiunto; entrambe le versioni precedenti ancora recuperabili |

## Comandi eseguiti e output

Verifica delle versioni dell'oggetto dopo la sovrascrittura:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws s3api list-object-versions \
  --bucket demo-vm-reti-storage-<iniziali>-2026 \
  --prefix report.txt \
  --query "Versions[].{VersionId:VersionId,IsLatest:IsLatest,Size:Size}"
```

**Windows PowerShell**

```powershell
aws s3api list-object-versions `
  --bucket demo-vm-reti-storage-<iniziali>-2026 `
  --prefix report.txt `
  --query "Versions[].{VersionId:VersionId,IsLatest:IsLatest,Size:Size}"
```

Output atteso (illustrativo: i Version ID reali sono stringhe alfanumeriche generate da S3):

```
[
    {"VersionId": "def456...", "IsLatest": true,  "Size": 42},
    {"VersionId": "abc123...", "IsLatest": false, "Size": 29}
]
```

Verifica dopo l'eliminazione del file (con versioning attivo):

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws s3api list-object-versions \
  --bucket demo-vm-reti-storage-<iniziali>-2026 \
  --prefix report.txt \
  --query "{Versions:Versions[].VersionId, DeleteMarkers:DeleteMarkers[].VersionId}"
```

**Windows PowerShell**

```powershell
aws s3api list-object-versions `
  --bucket demo-vm-reti-storage-<iniziali>-2026 `
  --prefix report.txt `
  --query "{Versions:Versions[].VersionId, DeleteMarkers:DeleteMarkers[].VersionId}"
```

Output atteso:

```
{
    "Versions": ["def456...", "abc123..."],
    "DeleteMarkers": ["ghi789..."]
}
```

Il delete marker (`ghi789...`) conferma che l'oggetto è stato "eliminato" solo in apparenza: entrambe le versioni precedenti restano presenti e recuperabili tramite il loro Version ID.

## Template operativo

```markdown
# Deliverable Lab 08

## Bucket
- Nome: demo-vm-reti-storage-<iniziali>-2026
- Versioning: Enabled

## Versioni di report.txt
- Versione 1 (originale): Version ID abc123...
- Versione 2 (sovrascritta): Version ID def456...

## Regola di lifecycle
- Nome: demo-lifecycle-standard-ia
- Logica: transizione versioni non correnti a Standard-IA dopo 30 giorni

## Evidenza eliminazione
- Delete marker creato: si (Version ID ghi789...)
- Versioni precedenti ancora recuperabili: si

## Cleanup
- Tutte le versioni e i delete marker eliminati: si/no
- Bucket eliminato: si/no
```

## Esempio sintetico

- Decisione corretta: verificare l'eliminazione con **Show versions** attivo, non fidarsi della vista di default che mostra il file come "sparito".
- Evidenza minima: due Version ID distinti per lo stesso file più il delete marker dopo l'eliminazione, non solo la configurazione del versioning.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare la policy di lifecycle e versioning pianificata su tabella Markdown.
- Cleanup atteso: tutte le versioni e i delete marker eliminati esplicitamente prima di rimuovere il bucket (un bucket con versioning attivo non si elimina se contiene ancora versioni).

## Checkpoint

- [x] Nome del bucket univoco a livello globale, creazione senza errori di conflitto
- [x] Versioning attivo, sovrascrittura del file ha prodotto una nuova versione senza perdere la precedente
- [x] Regola di lifecycle configurata con logica esplicita (transizione a Standard-IA dopo 30 giorni)
- [x] Cleanup completo (tutte le versioni e delete marker rimossi) eseguito o giustificato

## Errori comuni da evitare

- Verificare l'eliminazione solo dalla vista di default (senza **Show versions**), concludendo erroneamente che il file sia perso per sempre.
- Attivare il versioning senza collegare una regola di lifecycle, lasciando accumulare versioni indefinitamente.
- Tentare di eliminare il bucket senza aver prima rimosso tutte le versioni e i delete marker: l'operazione fallisce.
- Scegliere un nome di bucket generico che rischia un conflitto con altri account (il namespace è globale).

## Troubleshooting rapido

- Se la creazione del bucket fallisce con errore di nome già esistente, il nome è in conflitto globale con un altro account: scegli un nome più specifico.
- Se non vedi le versioni precedenti di un oggetto, verifica che la vista "List versions" (non solo "List objects") sia attiva nella console S3.
- Se la regola di lifecycle non viene salvata, verifica che il formato JSON (se usato da CLI) sia valido e che includa un filtro (anche vuoto) per l'ambito della regola.
- Se l'eliminazione di un file lo fa sparire completamente dalla vista di default, ricorda che con il versioning attivo questo è normale: il file è ancora recuperabile tramite le versioni precedenti.

## Cleanup obbligatorio

- Elimina tutte le versioni degli oggetti nel bucket di test (non solo la versione corrente), incluso ogni delete marker.
- Elimina il bucket di test una volta svuotato completamente.
- Rimuovi la regola di lifecycle se il bucket viene mantenuto per altri scopi.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
